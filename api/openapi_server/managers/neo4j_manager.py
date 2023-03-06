import neo4j
import configparser
from typing import List
import re
from neo4j.exceptions import CypherSyntaxError
import json

from openapi_server.models.assay_type_property_info import AssayTypePropertyInfo  # noqa: E501
from openapi_server.models.codes_codes_obj import CodesCodesObj  # noqa: E501
from openapi_server.models.concept_detail import ConceptDetail  # noqa: E501
from openapi_server.models.concept_prefterm import ConceptPrefterm  # noqa: E501
from openapi_server.models.concept_sab_rel import ConceptSabRel  # noqa: E501
from openapi_server.models.concept_sab_rel_depth import ConceptSabRelDepth  # noqa: E501
from openapi_server.models.concept_term import ConceptTerm  # noqa: E501
from openapi_server.models.dataset_property_info import DatasetPropertyInfo  # noqa: E501
from openapi_server.models.path_item_concept_relationship_sab_prefterm import PathItemConceptRelationshipSabPrefterm  # noqa: E501
from openapi_server.models.qqst import QQST  # noqa: E501
from openapi_server.models.qconcept_tconcept_sab_rel import QconceptTconceptSabRel  # noqa: E501
from openapi_server.models.sab_code_term import SabCodeTerm  # noqa: E501
from openapi_server.models.sab_definition import SabDefinition  # noqa: E501
from openapi_server.models.sab_relationship_concept_term import SabRelationshipConceptTerm  # noqa: E501
from openapi_server.models.semantic_stn import SemanticStn  # noqa: E501
from openapi_server.models.sty_tui_stn import StyTuiStn  # noqa: E501
from openapi_server.models.termtype_code import TermtypeCode  # noqa: E501

import logging

logging.basicConfig(format='[%(asctime)s] %(levelname)s in %(module)s:%(lineno)d: %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    level=logging.INFO)
logger = logging.getLogger(__name__)

cypher_tail: str = \
    " CALL apoc.when(rel = []," \
    "  'RETURN concept AS related_concept, NULL AS rel_type, NULL AS rel_sab'," \
    "  'MATCH (concept)-[matched_rel]->(related_concept)" \
    "   WHERE any(x IN rel WHERE x IN [[Type(matched_rel),matched_rel.SAB],[Type(matched_rel),\"*\"],[\"*\",matched_rel.SAB],[\"*\",\"*\"]])" \
    "   RETURN related_concept, Type(matched_rel) AS rel_type, matched_rel.SAB AS rel_sab'," \
    "  {concept:concept,rel:rel})" \
    " YIELD value" \
    " WITH matched, value.related_concept AS related_concept, value.rel_type AS rel_type, value.rel_sab AS rel_sab" \
    " MATCH (code:Code)<-[:CODE]-(related_concept:Concept)-[:PREF_TERM]->(prefterm:Term)" \
    " WHERE (code.SAB IN $sab OR $sab = [])" \
    " OPTIONAL MATCH (code:Code)-[code2term]->(term:Term)" \
    " WHERE (code2term.CUI = related_concept.CUI) AND (Type(code2term) IN $tty OR $tty = [])" \
    " WITH *" \
    " CALL apoc.when(term IS NULL," \
    "  'RETURN \"PREF_TERM\" AS tty, prefterm as term'," \
    "  'RETURN Type(code2term) AS tty, term'," \
    "  {term:term,prefterm:prefterm,code2term:code2term})" \
    " YIELD value" \
    " WITH *, value.tty AS tty, value.term AS term" \
    " RETURN DISTINCT matched, rel_type, rel_sab, code.CodeID AS code_id, code.SAB AS code_sab," \
    "  code.CODE AS code_code, tty, term.name AS term, related_concept.CUI AS concept" \
    " ORDER BY size(term), code_id, tty DESC, rel_type, rel_sab, concept, matched"

cypher_head: str = \
    "CALL db.index.fulltext.queryNodes(\"Term_name\", '\\\"'+$queryx+'\\\"')" \
    " YIELD node" \
    " WITH node AS matched_term" \
    " MATCH (matched_term)" \
    " WHERE size(matched_term.name) = size($queryx)" \
    " WITH matched_term" \
    " OPTIONAL MATCH (matched_term:Term)<-[relationship]-(:Code)<-[:CODE]-(concept:Concept)" \
    " WHERE relationship.CUI = concept.CUI" \
    " OPTIONAL MATCH (matched_term:Term)<-[:PREF_TERM]-(concept:Concept)"


def rel_str_to_array(rels: List[str]) -> List[List]:
    rel_array: List[List] = []
    for rel in rels:
        m = re.match(r'([^[]+)\[([^]]+)\]', rel)
        rel = m[1]
        sab = m[2]
        rel_array.append([rel, sab])
    return rel_array


# Each 'rel' list item is a string of the form 'Type[SAB]' which is translated into the array '[Type(t),t.SAB]'
# The Type or SAB can be a wild card '*', so '*[SAB]', 'Type[*]', 'Type[SAB]' and even '*[*]' are valid
def parse_and_check_rel(rel: List[str]) -> List[List]:
    try:
        rel_list: List[List] = rel_str_to_array(rel)
    except TypeError:
        raise Exception(f"The rel optional parameter must be of the form 'Type[SAB]', 'Type[*]', '*[SAB], or '*[*]'",
                        400)
    for r in rel_list:
        if not re.match(r"\*|[a-zA-Z_]+", r[0]):
            raise Exception(f"Invalid Type in rel optional parameter list", 400)
        if not re.match(r"\*|[a-zA-Z_]+", r[1]):
            raise Exception(f"Invalid SAB in rel optional parameter list", 400)
    return rel_list


# https://editor.swagger.io/
class Neo4jManager(object):

    def __init__(self):
        config = configparser.ConfigParser()
        # [neo4j]
        # Server = bolt://localhost: 7687
        # Username = neo4j
        # Password = password
        config.read('openapi_server/resources/app.properties')
        neo4j_config = config['neo4j']
        server = neo4j_config.get('Server')
        username = neo4j_config.get('Username')
        password = neo4j_config.get('Password')
        self.driver = neo4j.GraphDatabase.driver(server, auth=(username, password))

    # https://neo4j.com/docs/api/python-driver/current/api.html
    def close(self):
        self.driver.close()

    def codes_code_id_codes_get(self, code_id: str, sab: List[str]) -> List[CodesCodesObj]:
        codesCodesObjs: List[CodesCodesObj] = []
        query: str = \
            'WITH [$code_id] AS query' \
            ' MATCH (a:Code)<-[:CODE]-(b:Concept)-[:CODE]->(c:Code)' \
            ' WHERE a.CodeID IN query AND (c.SAB IN $SAB OR $SAB = [])' \
            ' RETURN DISTINCT a.CodeID AS Code1, b.CUI as Concept, c.CodeID AS Code2, c.SAB AS Sab2' \
            ' ORDER BY Code1, Concept ASC, Code2, Sab2'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, code_id=code_id, SAB=sab)
            for record in recds:
                try:
                    codesCodesObj: CodesCodesObj = \
                        CodesCodesObj(record.get('Concept'), record.get('Code2'), record.get('Sab2'))
                    codesCodesObjs.append(codesCodesObj)
                except KeyError:
                    pass
        return codesCodesObjs

    def codes_code_id_concepts_get(self, code_id: str) -> List[ConceptDetail]:
        conceptDetails: List[ConceptDetail] = []
        query: str = \
            'WITH [$code_id] AS query' \
            ' MATCH (a:Code)<-[:CODE]-(b:Concept)' \
            ' WHERE a.CodeID IN query' \
            ' OPTIONAL MATCH (b)-[:PREF_TERM]->(c:Term)' \
            ' RETURN DISTINCT a.CodeID AS Code, b.CUI AS Concept, c.name as Prefterm' \
            ' ORDER BY Code ASC, Concept'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, code_id=code_id)
            for record in recds:
                try:
                    conceptDetail: ConceptDetail = ConceptDetail(record.get('Concept'), record.get('Prefterm'))
                    conceptDetails.append(conceptDetail)
                except KeyError:
                    pass
        return conceptDetails

    # https://neo4j.com/docs/api/python-driver/current/api.html#explicit-transactions
    def concepts_concept_id_codes_get(self, concept_id: str, sab: List[str]) -> List[str]:
        codes: List[str] = []
        query: str = \
            'WITH [$concept_id] AS query' \
            ' MATCH (a:Concept)-[:CODE]->(b:Code)' \
            ' WHERE a.CUI IN query AND (b.SAB IN $SAB OR $SAB = [])' \
            ' RETURN DISTINCT a.CUI AS Concept, b.CodeID AS Code, b.SAB AS Sab' \
            ' ORDER BY Concept, Code ASC'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, concept_id=concept_id, SAB=sab)
            for record in recds:
                try:
                    code = record.get('Code')
                    codes.append(code)
                except KeyError:
                    pass
        return codes

    def concepts_concept_id_concepts_get(self, concept_id: str) -> List[SabRelationshipConceptTerm]:
        sabRelationshipConceptPrefterms: [SabRelationshipConceptPrefterm] = []
        query: str = \
            'WITH [$concept_id] AS query' \
            ' MATCH (b:Concept)<-[c]-(d:Concept)' \
            ' WHERE b.CUI IN query' \
            ' OPTIONAL MATCH (b)-[:PREF_TERM]->(a:Term)' \
            ' OPTIONAL MATCH (d)-[:PREF_TERM]->(e:Term)' \
            ' RETURN DISTINCT a.name AS Prefterm1, b.CUI AS Concept1, c.SAB AS SAB, type(c) AS Relationship,' \
            '  d.CUI AS Concept2, e.name AS Prefterm2' \
            ' ORDER BY Concept1, Relationship, Concept2 ASC, Prefterm1, Prefterm2'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, concept_id=concept_id)
            for record in recds:
                try:
                    sabRelationshipConceptPrefterm: SabRelationshipConceptPrefterm = \
                        SabRelationshipConceptPrefterm(record.get('SAB'), record.get('Relationship'),
                                                       record.get('Concept2'), record.get('Prefterm2'))
                    sabRelationshipConceptPrefterms.append(sabRelationshipConceptPrefterm)
                except KeyError:
                    pass
        return sabRelationshipConceptPrefterms

    def concepts_concept_id_definitions_get(self, concept_id: str) -> List[SabDefinition]:
        sabDefinitions: [SabDefinition] = []
        query: str = \
            'WITH [$concept_id] AS query' \
            ' MATCH (a:Concept)-[:DEF]->(b:Definition)' \
            ' WHERE a.CUI in query' \
            ' RETURN DISTINCT a.CUI AS Concept, b.SAB AS SAB, b.DEF AS Definition' \
            ' ORDER BY Concept, SAB'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, concept_id=concept_id)
            for record in recds:
                try:
                    sabDefinition: SabDefinition = SabDefinition(record.get('SAB'), record.get('Definition'))
                    sabDefinitions.append(sabDefinition)
                except KeyError:
                    pass
        return sabDefinitions

    def concepts_concept_id_semantics_get(self, concept_id) -> List[StyTuiStn]:
        styTuiStns: [StyTuiStn] = []
        query: str = \
            'WITH [$concept_id] AS query' \
            ' MATCH (a:Concept)-[:STY]->(b:Semantic)' \
            ' WHERE a.CUI IN query' \
            ' RETURN DISTINCT a.CUI AS concept, b.name AS STY, b.TUI AS TUI, b.STN as STN'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, concept_id=concept_id)
            for record in recds:
                try:
                    styTuiStn: StyTuiStn = StyTuiStn(record.get('STY'), record.get('TUI'), record.get('STN'))
                    styTuiStns.append(styTuiStn)
                except KeyError:
                    pass
        return styTuiStns

    def concepts_expand_post(self, concept_sab_rel_depth: ConceptSabRelDepth) -> List[ConceptPrefterm]:
        logger.info(f'concepts_expand_post; Request Body: {concept_sab_rel_depth.to_dict()}')
        conceptPrefterms: [ConceptPrefterm] = []
        query: str = \
            "MATCH (c:Concept {CUI: $query_concept_id})" \
            " CALL apoc.path.expand(c, apoc.text.join([x IN [$rel] | '<'+x], '|'), 'Concept', 1, $depth)" \
            " YIELD path" \
            " WHERE ALL(r IN relationships(path) WHERE r.SAB IN [$sab])" \
            " UNWIND nodes(path) AS con OPTIONAL MATCH (con)-[:PREF_TERM]->(pref:Term)" \
            " RETURN DISTINCT con.CUI as concept, pref.name as prefterm"
        # TODO: There seems to be a BUG in 'session.run' where it cannot handle arrays correctly?!
        sab: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel_depth.sab)
        query = query.replace('$sab', sab)
        rel: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel_depth.rel)
        # logger.info(f'Converted from array to string... sab: {sab} ; rel: {rel}')
        query = query.replace('$rel', rel)
        logger.info(f'query: "{query}"')
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query,
                                              query_concept_id=concept_sab_rel_depth.query_concept_id,
                                              # sab=sab,
                                              # rel=rel,
                                              depth=concept_sab_rel_depth.depth
                                              )
            for record in recds:
                try:
                    conceptPrefterm: ConceptPrefterm = \
                        ConceptPrefterm(record.get('concept'), record.get('prefterm'))
                    conceptPrefterms.append(conceptPrefterm)
                except KeyError:
                    pass
        return conceptPrefterms

    def concepts_path_post(self, concept_sab_rel: ConceptSabRel) -> List[PathItemConceptRelationshipSabPrefterm]:
        logger.info(f'concepts_path_post; Request Body: {concept_sab_rel.to_dict()}')
        pathItemConceptRelationshipSabPrefterms: [PathItemConceptRelationshipSabPrefterm] = []
        query: str = \
            "MATCH (c:Concept {CUI: $query_concept_id})" \
            " CALL apoc.path.expandConfig(c, {relationshipFilter: apoc.text.join([x in [$rel] | '<'+x], ','),minLevel: size([$rel]),maxLevel: size([$rel])})" \
            " YIELD path" \
            " WHERE ALL(r IN relationships(path) WHERE r.SAB IN [$sab])" \
            " WITH [n IN nodes(path) | n.CUI] AS concepts, [null]+[r IN relationships(path) |Type(r)] AS relationships, [null]+[r IN relationships(path) | r.SAB] AS sabs" \
            " CALL{WITH concepts,relationships,sabs UNWIND RANGE(0, size(concepts)-1) AS items WITH items AS item, concepts[items] AS concept, relationships[items] AS relationship, sabs[items] AS sab RETURN COLLECT([item,concept,relationship,sab]) AS paths}" \
            " WITH COLLECT(paths) AS rollup" \
            " UNWIND RANGE(0, size(rollup)-1) AS path" \
            " UNWIND rollup[path] as final" \
            " OPTIONAL MATCH (:Concept{CUI:final[1]})-[:PREF_TERM]->(prefterm:Term)" \
            " RETURN path as path, final[0] AS item, final[1] AS concept, final[2] AS relationship, final[3] AS sab, prefterm.name as prefterm"
        # TODO: There seems to be a BUG in 'session.run' where it cannot handle arrays correctly?!
        sab: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel.sab)
        query = query.replace('$sab', sab)
        rel: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel.rel)
        query = query.replace('$rel', rel)
        logger.info(f'query: "{query}"')
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query,
                                              query_concept_id=concept_sab_rel.query_concept_id,
                                              # sab=concept_sab_rel.sab,
                                              # rel=concept_sab_rel.rel
                                              )
            for record in recds:
                try:
                    pathItemConceptRelationshipSabPrefterm: PathItemConceptRelationshipSabPrefterm = \
                        PathItemConceptRelationshipSabPrefterm(record.get('path'), record.get('item'),
                                                               record.get('concept'), record.get('relationship'),
                                                               record.get('sab'), record.get('prefterm'))
                    pathItemConceptRelationshipSabPrefterms.append(pathItemConceptRelationshipSabPrefterm)
                except KeyError:
                    pass
        return pathItemConceptRelationshipSabPrefterms

    def concepts_shortestpaths_post(self, qconcept_tconcept_sab_rel: QconceptTconceptSabRel) -> List[
        PathItemConceptRelationshipSabPrefterm]:
        logger.info(f'concepts_shortestpath_post; Request Body: {qconcept_tconcept_sab_rel.to_dict()}')
        pathItemConceptRelationshipSabPrefterms: [PathItemConceptRelationshipSabPrefterm] = []
        query: str = \
            "MATCH (c:Concept {CUI: $query_concept_id})" \
            " MATCH (d:Concept {CUI: $target_concept_id})" \
            " CALL apoc.algo.dijkstraWithDefaultWeight(c, d, apoc.text.join([x in [$rel] | '<'+x], '|'), 'none', 10)" \
            " YIELD path" \
            " WHERE ALL(r IN relationships(path) WHERE r.SAB IN [$sab])" \
            " WITH [n IN nodes(path) | n.CUI] AS concepts, [null]+[r IN relationships(path) |Type(r)] AS relationships, [null]+[r IN relationships(path) | r.SAB] AS sabs" \
            " CALL{WITH concepts,relationships,sabs UNWIND RANGE(0, size(concepts)-1) AS items WITH items AS item, concepts[items] AS concept, relationships[items] AS relationship, sabs[items] AS sab RETURN COLLECT([item,concept,relationship,sab]) AS paths}" \
            " WITH COLLECT(paths) AS rollup" \
            " UNWIND RANGE(0, size(rollup)-1) AS path" \
            " UNWIND rollup[path] as final" \
            " OPTIONAL MATCH (:Concept{CUI:final[1]})-[:PREF_TERM]->(prefterm:Term)" \
            " RETURN path as path, final[0] AS item, final[1] AS concept, final[2] AS relationship, final[3] AS sab, prefterm.name as prefterm"
        # TODO: There seems to be a BUG in 'session.run' where it cannot handle arrays correctly?!
        sab: str = ', '.join("'{0}'".format(s) for s in qconcept_tconcept_sab_rel.sab)
        query = query.replace('$sab', sab)
        rel: str = ', '.join("'{0}'".format(s) for s in qconcept_tconcept_sab_rel.rel)
        query = query.replace('$rel', rel)
        logger.info(f'query: "{query}"')
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query,
                                              query_concept_id=qconcept_tconcept_sab_rel.query_concept_id,
                                              # sab=concept_sab_rel.sab,
                                              # rel=concept_sab_rel.rel,
                                              target_concept_id=qconcept_tconcept_sab_rel.target_concept_id
                                              )
            for record in recds:
                try:
                    pathItemConceptRelationshipSabPrefterm: PathItemConceptRelationshipSabPrefterm = \
                        PathItemConceptRelationshipSabPrefterm(record.get('path'), record.get('item'),
                                                               record.get('concept'), record.get('relationship'),
                                                               record.get('sab'), record.get('prefterm'))
                    pathItemConceptRelationshipSabPrefterms.append(pathItemConceptRelationshipSabPrefterm)
                except KeyError:
                    pass
        return pathItemConceptRelationshipSabPrefterms

    def concepts_trees_post(self, concept_sab_rel_depth: ConceptSabRelDepth) -> List[
        PathItemConceptRelationshipSabPrefterm]:
        logger.info(f'concepts_trees_post; Request Body: {concept_sab_rel_depth.to_dict()}')
        pathItemConceptRelationshipSabPrefterms: [PathItemConceptRelationshipSabPrefterm] = []
        query: str = \
            "MATCH (c:Concept {CUI: $query_concept_id})" \
            " CALL apoc.path.spanningTree(c, {relationshipFilter: apoc.text.join([x in [$rel] | '<'+x], '|'),minLevel: 1,maxLevel: $depth})" \
            " YIELD path" \
            " WHERE ALL(r IN relationships(path) WHERE r.SAB IN [$sab])" \
            " WITH [n IN nodes(path) | n.CUI] AS concepts, [null]+[r IN relationships(path) |Type(r)] AS relationships, [null]+[r IN relationships(path) | r.SAB] AS sabs" \
            " CALL{WITH concepts,relationships,sabs UNWIND RANGE(0, size(concepts)-1) AS items WITH items AS item, concepts[items] AS concept, relationships[items] AS relationship, sabs[items] AS sab RETURN COLLECT([item,concept,relationship,sab]) AS paths}" \
            " WITH COLLECT(paths) AS rollup" \
            " UNWIND RANGE(0, size(rollup)-1) AS path" \
            " UNWIND rollup[path] as final" \
            " OPTIONAL MATCH (:Concept{CUI:final[1]})-[:PREF_TERM]->(prefterm:Term)" \
            " RETURN path as path, final[0] AS item, final[1] AS concept, final[2] AS relationship, final[3] AS sab, prefterm.name as prefterm"
        # TODO: There seems to be a BUG in 'session.run' where it cannot handle arrays correctly?!
        sab: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel_depth.sab)
        query = query.replace('$sab', sab)
        rel: str = ', '.join("'{0}'".format(s) for s in concept_sab_rel_depth.rel)
        query = query.replace('$rel', rel)
        logger.info(f'query: "{query}"')
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query,
                                              query_concept_id=concept_sab_rel_depth.query_concept_id,
                                              # sab=concept_sab_rel_depth.sab,
                                              # rel=concept_sab_rel_depth.rel,
                                              depth=concept_sab_rel_depth.depth
                                              )
            for record in recds:
                try:
                    pathItemConceptRelationshipSabPrefterm: PathItemConceptRelationshipSabPrefterm = \
                        PathItemConceptRelationshipSabPrefterm(record.get('path'), record.get('item'),
                                                               record.get('concept'), record.get('relationship'),
                                                               record.get('sab'), record.get('prefterm'))
                    pathItemConceptRelationshipSabPrefterms.append(pathItemConceptRelationshipSabPrefterm)
                except KeyError:
                    pass
        return pathItemConceptRelationshipSabPrefterms

    def semantics_semantic_id_semantics_get(self, semantic_id: str) -> List[QQST]:
        qqsts: [QQST] = []
        query: str = \
            'WITH [$semantic_id] AS query' \
            ' MATCH (a:Semantic)-[:ISA_STY]->(b:Semantic)' \
            ' WHERE (a.name IN query OR query = [])' \
            ' RETURN DISTINCT a.name AS querySemantic, a.TUI as queryTUI, a.STN as querySTN, b.name AS semantic,' \
            '  b.TUI AS TUI, b.STN as STN'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, semantic_id=semantic_id)
            for record in recds:
                try:
                    qqst: QQST = QQST(record.get('queryTUI'), record.get('querySTN'), record.get('semantic'),
                                      record.get('TUI'), record.get('STN'))
                    qqsts.append(qqst)
                except KeyError:
                    pass
        return qqsts

    def terms_term_id_codes_get(self, term_id: str) -> List[TermtypeCode]:
        termtypeCodes: [TermtypeCode] = []
        query: str = \
            'WITH [$term_id] AS query' \
            ' MATCH (a:Term)<-[b]-(c:Code)' \
            ' WHERE a.name IN query' \
            ' RETURN DISTINCT a.name AS Term, Type(b) AS TermType, c.CodeID AS Code' \
            ' ORDER BY Term, TermType, Code'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, term_id=term_id)
            for record in recds:
                try:
                    termtypeCode: TermtypeCode = TermtypeCode(record.get('TermType'), record.get('Code'))
                    termtypeCodes.append(termtypeCode)
                except KeyError:
                    pass
        return termtypeCodes

    def terms_term_id_concepts_get(self, term_id: str) -> List[str]:
        concepts: [str] = []
        query: str = \
            'WITH [$term_id] AS query' \
            ' OPTIONAL MATCH (a:Term)<-[b]-(c:Code)<-[:CODE]-(d:Concept)' \
            ' WHERE a.name IN query AND b.CUI = d.CUI' \
            ' OPTIONAL MATCH (a:Term)<--(d:Concept) WHERE a.name IN query' \
            ' RETURN DISTINCT a.name AS Term, d.CUI AS Concept' \
            ' ORDER BY Concept ASC'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, term_id=term_id)
            for record in recds:
                try:
                    concept: str = record.get('Concept')
                    concepts.append(concept)
                except KeyError:
                    pass
        return concepts

    def terms_term_id_concepts_terms_get(self, term_id: str) -> List[ConceptTerm]:
        conceptTerms: [ConceptTerm] = []
        query: str = \
            'WITH [$term_id] AS query' \
            ' OPTIONAL MATCH (a:Term)<-[b]-(c:Code)<-[:CODE]-(d:Concept)' \
            ' WHERE a.name IN query AND b.CUI = d.CUI' \
            ' OPTIONAL MATCH (a:Term)<--(d:Concept)' \
            ' WHERE a.name IN query WITH a,collect(d.CUI) AS next' \
            ' MATCH (f:Term)<-[:PREF_TERM]-(g:Concept)-[:CODE]->(h:Code)-[i]->(j:Term)' \
            ' WHERE g.CUI IN next AND g.CUI = i.CUI' \
            ' WITH a, g,COLLECT(j.name)+[f.name] AS x' \
            ' WITH * UNWIND(x) AS Term2' \
            ' RETURN DISTINCT a.name AS Term1, g.CUI AS Concept, Term2' \
            ' ORDER BY Term1, Term2'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, term_id=term_id)
            for record in recds:
                try:
                    conceptTerm: ConceptTerm = ConceptTerm(record.get('Concept'), record.get('Term2'))
                    conceptTerms.append(conceptTerm)
                except KeyError:
                    pass
        return conceptTerms

    def tui_tui_id_semantics_get(self, tui_id: str) -> List[SemanticStn]:
        semanticStns: [SemanticStn] = []
        query: str = \
            'WITH [$tui_id] AS query' \
            ' MATCH (a:Semantic)' \
            ' WHERE (a.TUI IN query OR query = [])' \
            ' RETURN DISTINCT a.name AS semantic, a.TUI AS TUI, a.STN AS STN1'
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query, tui_id=tui_id)
            for record in recds:
                try:
                    semanticStn: SemanticStn = SemanticStn(record.get('semantic'), record.get('STN1'))
                    semanticStns.append(semanticStn)
                except KeyError:
                    pass
        return semanticStns

    # -----------------------------
    # HUBMAP/SENNET ENDPOINTS

    def valueset_get(self, parent_sab: str, parent_code: str, child_sabs: List[str]) -> List[SabCodeTerm]:
        # JAS 29 NOV 2022
        # Returns a valueset of concepts that are children (have as isa relationship) of another concept.

        # A valueset is defined as the set of terms associated the concept's child concepts. The parent
        # concept acts as an aggregator of concepts from multiple SABs. The main use case for a valueset
        # is an encoded set of terms that correspond to the possible answers for a categorical question.

        # The argument child_sabs is list of SABs from which to select child concepts, in order of
        # preference. If a parent concept has a cross-reference with another concept, it is likely that the
        # cross-referenced concept has child concepts from many SABs, especially if the cross-referenced concept
        # is from the UMLS. The order of SABs in the list indicates the order in which child concepts should be
        # selected.

        sabcodeterms: [SabCodeTerm] = []

        # Build clauses of the query that depend on child_sabs, including:
        # 1. an IN statement
        # 2. The CASE statement that will be used twice in the correlated subquery.
        #    The CASE statement orders the codes for child concepts by where the SABs for the child concepts
        #    occur in the child_sabs list.

        sab_case: str = 'CASE codeChild.SAB '
        sab_in: str = '['
        for index, item in enumerate(child_sabs):
            sab_case = sab_case + ' WHEN \'' + item + '\' THEN ' + str(index + 1)
            sab_in = sab_in + '\'' + item + '\''
            if index < len(child_sabs) - 1:
                sab_in = sab_in + ', '
        sab_case = sab_case + ' END'
        sab_in = sab_in + ']'

        # Build correlated subquery.

        # 1. Find the child concepts with an isa relationship with the parent HUBMAP concept (identified by code).
        # 2. Order the child concepts based on the positions of the SABs for their codes in a list
        #    (as opposed to an alphabetic order).
        # 3. Identify the code from the SAB that is the earliest in the list.  For example,
        #    if codes from SNOMEDCT_US are preferred to those from NCI, the list would include
        #    [...,'SNOMEDCT_US','NCI',...].

        query: str = 'CALL'
        query = query + '{'
        query = query + 'MATCH (codeChild:Code)<-[:CODE]-(conceptChild:Concept)-[:isa]->(conceptParent:Concept)-[' \
                        ':CODE]->(codeParent:Code) '
        query = query + ' WHERE codeParent.SAB=\'' + parent_sab + '\' AND codeParent.CODE=\'' + parent_code + '\''
        query = query + ' AND codeChild.SAB IN ' + sab_in
        query = query + ' RETURN conceptChild.CUI AS conceptChildCUI, min(' + sab_case + ') AS minSAB'
        query = query + ' ORDER BY conceptChildCUI'
        query = query + '}'

        # 4. Filter to the code for the child concepts with the "earliest" SAB. The "earliest" SAB will be different for
        #    each child concept.  Limit to 1 to account for multiple cross-references (e.g., UMLS C0026018, which maps
        #    to 2 NCI codes).
        query = query + ' CALL'
        query = query + '{'
        query = query + 'WITH conceptChildCUI, minSAB '
        query = query + 'MATCH (codeChild:Code)<-[:CODE]-(conceptChild:Concept) '
        query = query + 'WHERE conceptChild.CUI = conceptChildCUI '
        query = query + 'AND ' + sab_case + ' = minSAB '
        query = query + 'RETURN codeChild '
        query = query + 'ORDER BY codeChild.CODE '
        query = query + 'LIMIT 1'
        query = query + '} '

        # Get the term associated with the child concept code with the earliest SAB.
        query = query + 'WITH codeChild '
        query = query + 'MATCH (termChild:Term)<-[:PT]-(codeChild:Code) '
        query = query + 'RETURN termChild.name AS term, codeChild.CODE as code,codeChild.SAB as sab'

        # Execute Cypher query and return result.
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query)
            for record in recds:
                try:
                    sabcodeterm: [SabCodeTerm] = SabCodeTerm(record.get('sab'), record.get('code'), record.get('term'))
                    sabcodeterms.append(sabcodeterm)
                except KeyError:
                    pass

        return sabcodeterms

    def __subquery_dataset_synonym_property(self, sab: str, cuialias: str, returnalias: str, collectvalues: bool) -> str:
        # JAS FEB 2023
        # Returns a subquery to obtain a "synonym" relationship property. See __query_dataset_info for an explanation.

        # arguments:
        # sab: SAB for the application
        # cuialias = Alias for the CUI passed to the WITH statement
        # returnalias = Alias for the return of the query
        # collectvalues: whether to use COLLECT

        qry = ''
        qry = qry + 'CALL '
        qry = qry + '{'
        qry = qry + 'WITH ' + cuialias + ' '
        qry = qry + 'OPTIONAL MATCH (pDatasetThing:Concept)-[:CODE]->(cDatasetThing:Code)-[rCodeTerm:SY]->(tSyn:Term)  '
        qry = qry + 'WHERE cDatasetThing.SAB = \'' + sab + '\''
        # In a (Concept)->(Code)->(Term) path in the KG, the relationship between the Code and Term
        # shares the CUI with the Concept.
        qry = qry + 'AND rCodeTerm.CUI = pDatasetThing.CUI '
        qry = qry + 'AND pDatasetThing.CUI = ' + cuialias + ' '
        qry = qry + 'RETURN '
        if collectvalues:
            retval = 'COLLECT(tSyn.name) '
        else:
            retval = 'tSyn.name'
        qry = qry + retval + ' AS ' + returnalias
        qry = qry + '}'

        return qry

    def __subquery_dataset_relationship_property(self, sab: str, cuialias: str, rel_string: str, returnalias: str, isboolean: bool = False, collectvalues: bool = False, codelist: List[str] = []) -> str:

        # JAS FEB 2023
        # Returns a subquery to obtain a "relationship property". See __query_dataset_info for an explanation.

        # There are two types of relationship properties:
        # 1. The entity that associates with cuialias corresponds to the term of a related entity.
        # 2. In a "boolean" relationship, the property is true if the entity that associates with cuialias has a
        #    link of type rel_string to another code (via concepts).

        # arguments:
        # sab: SAB for the application
        # cuialias: Alias for the CUI passed to the WITH statement
        # rel_string: label for the relationship
        # returnalias:  Alias for the return of the query
        # codelist: list of specific codes that are objects of relationships
        # collectvalues: whether to use COLLECT
        # isboolean: check for the existence of link instead of a term

        qry = ''
        qry = qry + 'CALL '
        qry = qry + '{'
        qry = qry + 'WITH ' + cuialias + ' '
        qry = qry + 'OPTIONAL MATCH (pDatasetThing:Concept)-[rProperty:' + rel_string + ']->(pProperty:Concept)'

        if len(codelist) > 0:
            # Link against specific codes
            qry = qry + '-[:CODE]->(cProperty:Code)-[rCodeTerm:PT]->(tProperty:Term) '
        else:
            # Link against concepts
            qry = qry + '-[rConceptTerm:PREF_TERM]->(tProperty:Term) '

        qry = qry + 'WHERE pDatasetThing.CUI = ' + cuialias + ' '
        qry = qry + 'AND rProperty.SAB =\'' + sab + '\' '

        if len(codelist) > 0:
            # Link against specific codes.
            qry = qry + 'AND cProperty.SAB = \'' + sab + '\' '
            # In a (Concept)->(Code)->(Term) path in the KG, the relationship between the Code and Term
            # shares the CUI with the Concept.
            qry = qry + 'AND rCodeTerm.CUI = pProperty.CUI '
            qry = qry + 'AND cProperty.CODE IN [' + ','.join("'{0}'".format(x) for x in codelist) + '] '

        qry = qry + 'RETURN '
        if collectvalues:
            if rel_string == 'has_vitessce_hint':
                # Special case: some vitessce hint nodes have terms with the substring '_vitessce_hint' added.
                # This is an artifact of a requirement of the SimpleKnowledge Editor that should not be in the
                # returned result. Strip the substring.
                retval = 'COLLECT(REPLACE(tProperty.name,\'_vitessce_hint\',\'\'))'
            else:
                retval = 'COLLECT(tProperty.name) '
        elif isboolean:
            retval = 'cProperty.CodeID IS NOT NULL '
        elif 'C004003' in codelist:
            # Special case: map dataset orders to true or false
            retval = 'CASE cProperty.CODE WHEN \'C004003\' THEN true WHEN \'C004004\' THEN false ELSE \'\' END '
        else:
            # Force a blank in case of null value for a consistent return to the GET.
            retval = 'CASE tProperty.name WHEN NULL THEN \'\' ELSE tProperty.name END '

        qry = qry + retval + ' AS ' + returnalias
        qry = qry + '}'
        return qry

    def __subquery_data_type_info(self, sab: str) -> str:

        # JAS FEB 2023
        # Returns a Cypher subquery that obtains concept CUI and preferred term strings for the Dataset Data Type
        # codes in an application context. Dataset Data Type codes are in a hierarchy with a root entity with code
        # C004001 in the application context.

        # See __build_cypher_dataset_info for an explanation.

        # Arguments:
        # sab: the SAB for the application ontology context--i.e., either HUBMAP or SENNET
        # filter: filter for data_type

        qry = ''
        qry = qry + 'CALL '
        qry = qry + '{'
        qry = qry + 'MATCH (cParent:Code)<-[:CODE]-(pParent:Concept)<-[:isa]-(pChild:Concept)'
        qry = qry + '-[rConceptTerm:PREF_TERM]->(tChild:Term) '
        qry = qry + 'WHERE cParent.CodeID=\'' + sab + ' C004001\' '
        qry = qry + 'RETURN pChild.CUI AS data_typeCUI, tChild.name AS data_type'
        qry = qry + '} '
        return qry

    def __subquery_dataset_cuis(self, sab: str, cuialias: str, returnalias: str) -> str:

        # JAS FEB 2023
        # Returns a Cypher subquery that obtains concept CUIs for Dataset concepts in the application context.
        # The use case is that the concepts are related to the data_set CUIs passed in the cuialias parameter.

        # arguments:
        # sab: SAB for the application
        # cuialias: CUI to pass to the WITH statement
        # returnalias: alias for return

        qry = ''
        qry = qry + 'CALL '
        qry = qry + '{'
        qry = qry + 'WITH ' + cuialias + ' '
        qry = qry + 'OPTIONAL MATCH (pDataType:Concept)<-[r:has_data_type]-(pDataset:Concept)  '
        qry = qry + 'WHERE r.SAB =\'' + sab + '\' '
        qry = qry + 'AND pDataType.CUI = ' + cuialias + ' '
        qry = qry + 'RETURN pDataset.CUI AS ' + returnalias
        qry = qry + '}'

        return qry

    def __query_cypher_dataset_info(self, sab: str) -> str:

        # JAS FEB 2023
        # Returns a Cypher query string that will return property information on the datasets in an application
        # context (SAB in the KG), keyed by the data_type.

        # Arguments:
        # sab: the SAB for the application ontology context--i.e., either HUBMAP or SENNET

        # There are three types of "properties" for an entity in an ontology (i.e., those specified by assertion
        # in the SAB, and not lower-level infrastructural properties such as SAB or CUI):
        # 1. A "relationship property" corresponds to the name property of the Term node in a path that corresponds
        #    to an asserted relationship other than isa--i.e.,
        #    (Term)<-[:PT]-(Code)<-[:CODE]-(Concept)-[property relationship]-(Concept)-[:CODE]-(Code for Entity)
        # 2. A "hierarchy property" corresponds to a "relationship property" of a node to which the entity relates
        #    by means of an isa relationship.
        #    For example, the Dataset Order property (Primary Dataset, Derived Dataset) is actually a property of a
        #    subclass of Dataset Order to which Dataset relates via an isa relationship. If a Dataset isa
        #    Primary Dataset, then it has a "Dataset order" property of "Primary Dataset".
        # 3. A "synonym property", in which the property value corresponds to the name of a Term node that has a
        #    SY relationship with the Code node for the entity.

        # In an application ontology, dataset properties can associate with the dataset or the data_type.

        # The data_type is actually a property of a Dataset type  (relationship = has_data_type).
        # Instead of navigating from the Dataset types down to properties, the query will navigate from
        # the data_types up to the Dataset types and then down to the other dataset properties.

        # The original assay_types.yaml file has keys that use dashes instead of underscores--e.g., alt-names.
        # neo4j cannot interpret return variables that contain dashes, so the query string uses underscores--
        # e.g., alt_names. The ubkg-api-spec.yaml file uses dashes for key names for the return to the GET.

        sab = sab.upper()

        qry = ''

        # First, identify the CUIs and terms for data_type in the specified application.
        # The subquery will return:
        # data_typeCUI - used in the WITH clause of downstream subqueries for properties that link to the data_type.
        # data_type - used in the return
        qry = qry + self.__subquery_data_type_info(sab=sab)

        # Identify CUIs for dataset types that associate with the data_type.
        # The subquery will return DatasetCUI, used in the WITH clause of downstream subqueries that link to the
        # Dataset.
        qry = qry + ' ' + self.__subquery_dataset_cuis(sab=sab, cuialias='data_typeCUI', returnalias='DatasetCUI')

        # PROPERTY VALUE SUBQUERIES

        # Dataset display name: relationship property of the Dataset.
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='DatasetCUI',
                                                                        rel_string='has_display_name',
                                                                        returnalias='description')

        # alt_names: Synonym property, linked to the data_type.
        # Because a data_type can have multiple alt-names, collect values.
        qry = qry + ' ' + self.__subquery_dataset_synonym_property(sab=sab, cuialias='data_typeCUI',
                                                                   returnalias='alt_names',
                                                                   collectvalues=True)

        # dataset_order: relationship property, linked to Dataset.
        # C004003=Primary Dataset, C004004=Derived Dataset in both HuBMAP and SenNet.
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='DatasetCUI',
                                                                        rel_string='isa',
                                                                        returnalias='primary',
                                                                        codelist=['C004003', 'C004004'])

        # dataset_provider: relationship property of the Dataset.
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='DatasetCUI',
                                                                        rel_string='provided_by',
                                                                        returnalias='dataset_provider')

        # vis-only: "boolean" relationship property of the Dataset.
        # True = the Dataset isa <SAB> C004008 (vis-only).
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='DatasetCUI',
                                                                        rel_string='isa',
                                                                        returnalias='vis_only',
                                                                        isboolean=True,
                                                                        codelist=['C004008'])

        # contains_pii: "boolean" relationship property of the Dataset.
        # True = the Dataset has a path to code <SAB> C004009 (pii).
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='DatasetCUI',
                                                                        returnalias='contains_pii',
                                                                        rel_string='contains',
                                                                        isboolean=True,
                                                                        codelist=['C004009'])

        # vitessce_hints: list relationship property of the data_type.
        qry = qry + ' ' + self.__subquery_dataset_relationship_property(sab=sab, cuialias='data_typeCUI',
                                                                        rel_string='has_vitessce_hint',
                                                                        returnalias='vitessce_hints',
                                                                        collectvalues=True)

        # Order and sort output
        qry = qry + ' '
        qry = qry + 'WITH data_type, description, alt_names, primary, dataset_provider, vis_only, contains_pii, vitessce_hints '
        qry = qry + 'RETURN data_type, description, alt_names, primary, dataset_provider, vis_only, contains_pii, vitessce_hints '
        qry = qry + 'ORDER BY tolower(data_type)'
        return qry

    def dataset_get(self, application_context: str, data_type: str = '', description: str = '', alt_name: str = '', primary: str = '', contains_pii: str = '', vis_only: str = '', vitessce_hint: str = '', dataset_provider: str = '') -> List[DatasetPropertyInfo]:

        # JAS FEB 2023
        # Returns an array of objects corresponding to Dataset (type) nodes in the HubMAP
        # or SenNet application ontology.
        # The return replicates the content of the original assay_types.yaml file, and adds new
        # dataset properties that were not originally in that file.

        # Arguments:
        # application_context: HUBMAP or SENNET
        # data_type...vitessce_hint: specific filtering values of properties

        # Notes:
        # 1. The order of the optional arguments must match the order of parameters in the corresponding path in the
        #    spec.yaml file.
        # 2. The field names in the response match the original keys in the original asset_types.yaml file.
        #    Unfortunately, some of these keys have names that use dashes (e.g., vis-only). Dashes are interpreted as
        #    subtraction operators in both the GET URL and in neo4j queries. This means that the parameters
        #    must use underscores instead of dashes--e.g., to filter on "vis-only", the parameter is "vis_only".

        datasets: [DatasetPropertyInfo] = []

        # Build the Cypher query that will return the table of data.
        query = self.__query_cypher_dataset_info(application_context)

        # Execute Cypher query and return result.
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query)

            for record in recds:
                # Because the Cypher query concatenates a set of subqueries, filtering by a parameter
                # can only be done with the full return, except for the case of the initial subquery.

                # Filtering is additive--i.e., boolean AND.

                includerecord = True
                if data_type is not None:
                    includerecord = includerecord and record.get('data_type') == data_type

                if description is not None:
                    includerecord = includerecord and record.get('description') == description

                if alt_name is not None:
                    includerecord = includerecord and alt_name in record.get('alt_names')

                if primary is not None:
                    primarybool = primary.lower() == "true"
                    includerecord = includerecord and record.get('primary') == primarybool

                if vis_only is not None:
                    visbool = vis_only.lower() == "true"
                    includerecord = includerecord and record.get('vis_only') == visbool

                if vitessce_hint is not None:
                    includerecord = includerecord and vitessce_hint in record.get('vitessce_hints')

                if dataset_provider is not None:
                    if dataset_provider.lower() == 'iec':
                        prov = application_context + ' IEC'
                    else:
                        prov = 'External Provider'
                    includerecord = includerecord and record.get('dataset_provider').lower() == prov.lower()

                if contains_pii is not None:
                    piibool = contains_pii.lower() == "true"
                    includerecord = includerecord and record.get('contains_pii') == piibool

                if includerecord:
                    try:
                        dataset: [DatasetPropertyInfo] = DatasetPropertyInfo(record.get('alt_names'),
                                                                             record.get('contains_pii'),
                                                                             record.get('data_type'),
                                                                             record.get('dataset_provider'),
                                                                             record.get('description'),
                                                                             record.get('primary'),
                                                                             record.get('vis_only'),
                                                                             record.get('vitessce_hints')
                                                                             )

                        datasets.append(dataset)
                    except KeyError:
                        pass

        return datasets

    def assaytype_name_get(self, name: str, application_context: str = 'HUBMAP') -> AssayTypePropertyInfo:
        """
        This is intended to be a drop in replacement for the same endpoint in search-api.

        The only difference is the optional application_contect to make it consistent with a HUBMAP or SENNET
        environment.
        """
        # datasets: List[DatasetPropertyInfo] = self.dataset_get(application_context, name)

        # Build the Cypher query that will return the table of data.
        query = self.__query_cypher_dataset_info(application_context)

        # Execute Cypher query and return result.
        with self.driver.session() as session:
            recds: neo4j.Result = session.run(query)
            for record in recds:
                if record.get('data_type') == name:
                    # Accessing the record by .get('str') does not appear to work?! :-(
                    return AssayTypePropertyInfo(
                        record[0],
                        record[3],
                        record[1],
                        record[7],
                        record[6],
                        record[5]
                    )
        return AssayTypePropertyInfo()
