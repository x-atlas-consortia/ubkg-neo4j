import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.assay_name_request import AssayNameRequest  # noqa: E501
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
from openapi_server import util
from openapi_server.managers.neo4j_manager import Neo4jManager


neo4jManager = Neo4jManager()


def assayname_post():  # noqa: E501
    """Replacement for the same endpoint in search-api

     # noqa: E501

    :param assay_name_request:
    :type assay_name_request: dict | bytes

    :rtype: Union[AssayTypePropertyInfo, Tuple[AssayTypePropertyInfo, int], Tuple[AssayTypePropertyInfo, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        assay_name_request = AssayNameRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return neo4jManager.assayname_post(assay_name_request)


def assaytype_name_get(name, application_context=None):  # noqa: E501
    """Replacement for the same endpoint in search-api with the addition of application_context

     # noqa: E501

    :param name: AssayType name
    :type name: str
    :param application_context: Filter to indicate application context
    :type application_context: str

    :rtype: Union[AssayTypePropertyInfo, Tuple[AssayTypePropertyInfo, int], Tuple[AssayTypePropertyInfo, int, Dict[str, str]]
    """
    return neo4jManager.assaytype_name_get(name, application_context)


def codes_code_id_codes_get(code_id, sab=None):  # noqa: E501
    """Returns a list of code_ids {Concept, Code, SAB} that code the same concept(s) as the code_id, optionally restricted to source (SAB)

     # noqa: E501

    :param code_id: The code identifier
    :type code_id: str
    :param sab: One or more sources (SABs) to return
    :type sab: List[str]

    :rtype: Union[List[CodesCodesObj], Tuple[List[CodesCodesObj], int], Tuple[List[CodesCodesObj], int, Dict[str, str]]
    """
    return neo4jManager.codes_code_id_codes_get(code_id, sab)


def codes_code_id_concepts_get(code_id):  # noqa: E501
    """Returns a list of concepts {Concept, Prefterm} that the code_id codes

     # noqa: E501

    :param code_id: The code identifier
    :type code_id: str

    :rtype: Union[List[ConceptDetail], Tuple[List[ConceptDetail], int], Tuple[List[ConceptDetail], int, Dict[str, str]]
    """
    return neo4jManager.codes_code_id_concepts_get(code_id)


def concepts_concept_id_codes_get(concept_id, sab=None):  # noqa: E501
    """Returns a distinct list of code_id(s) that code the concept

     # noqa: E501

    :param concept_id: The concept identifier
    :type concept_id: str
    :param sab: One or more sources (SABs) to return
    :type sab: List[str]

    :rtype: Union[List[str], Tuple[List[str], int], Tuple[List[str], int, Dict[str, str]]
    """
    return neo4jManager.concepts_concept_id_codes_get(concept_id, sab)


def concepts_concept_id_concepts_get(concept_id):  # noqa: E501
    """Returns a list of concepts {Sab, Relationship, Concept, Prefterm} related to the concept

     # noqa: E501

    :param concept_id: The concept identifier
    :type concept_id: str

    :rtype: Union[List[SabRelationshipConceptTerm], Tuple[List[SabRelationshipConceptTerm], int], Tuple[List[SabRelationshipConceptTerm], int, Dict[str, str]]
    """
    return neo4jManager.concepts_concept_id_concepts_get(concept_id)


def concepts_concept_id_definitions_get(concept_id):  # noqa: E501
    """Returns a list of definitions {Sab, Definition} of the concept

     # noqa: E501

    :param concept_id: The concept identifier
    :type concept_id: str

    :rtype: Union[List[SabDefinition], Tuple[List[SabDefinition], int], Tuple[List[SabDefinition], int, Dict[str, str]]
    """
    return neo4jManager.concepts_concept_id_definitions_get(concept_id)


def concepts_concept_id_semantics_get(concept_id):  # noqa: E501
    """Returns a list of semantic_types {Sty, Tui, Stn} of the concept

     # noqa: E501

    :param concept_id: The concept identifier
    :type concept_id: str

    :rtype: Union[List[StyTuiStn], Tuple[List[StyTuiStn], int], Tuple[List[StyTuiStn], int, Dict[str, str]]
    """
    return neo4jManager.concepts_concept_id_semantics_get(concept_id)


def concepts_expand_post():  # noqa: E501
    """Returns a unique list of concepts (Concept, Preferred Term) on all paths including starting concept (query_concept_id) restricted by list of relationship types (rel), list of relationship sources (sab), and depth of travel.

     # noqa: E501

    :param concept_sab_rel_depth:
    :type concept_sab_rel_depth: dict | bytes

    :rtype: Union[List[ConceptPrefterm], Tuple[List[ConceptPrefterm], int], Tuple[List[ConceptPrefterm], int, Dict[str, str]]
    """
    if connexion.request.is_json:
        concept_sab_rel_depth = ConceptSabRelDepth.from_dict(connexion.request.get_json())  # noqa: E501
    return neo4jManager.concepts_expand_post(concept_sab_rel_depth)


def concepts_path_post():  # noqa: E501
    """Return all paths of the relationship pattern specified within the selected sources

     # noqa: E501

    :param concept_sab_rel:
    :type concept_sab_rel: dict | bytes

    :rtype: Union[List[PathItemConceptRelationshipSabPrefterm], Tuple[List[PathItemConceptRelationshipSabPrefterm], int], Tuple[List[PathItemConceptRelationshipSabPrefterm], int, Dict[str, str]]
    """
    if connexion.request.is_json:
        concept_sab_rel = ConceptSabRel.from_dict(connexion.request.get_json())  # noqa: E501
    return neo4jManager.concepts_path_post(concept_sab_rel)


def concepts_shortestpaths_post():  # noqa: E501
    """Return all paths of the relationship pattern specified within the selected sources

     # noqa: E501

    :param qconcept_tconcept_sab_rel:
    :type qconcept_tconcept_sab_rel: dict | bytes

    :rtype: Union[List[PathItemConceptRelationshipSabPrefterm], Tuple[List[PathItemConceptRelationshipSabPrefterm], int], Tuple[List[PathItemConceptRelationshipSabPrefterm], int, Dict[str, str]]
    """
    if connexion.request.is_json:
        qconcept_tconcept_sab_rel = QconceptTconceptSabRel.from_dict(connexion.request.get_json())  # noqa: E501
    return neo4jManager.concepts_shortestpaths_post(qconcept_tconcept_sab_rel)


def concepts_trees_post():  # noqa: E501
    """Return all paths of the relationship pattern specified within the selected sources

     # noqa: E501

    :param concept_sab_rel_depth:
    :type concept_sab_rel_depth: dict | bytes

    :rtype: Union[List[PathItemConceptRelationshipSabPrefterm], Tuple[List[PathItemConceptRelationshipSabPrefterm], int], Tuple[List[PathItemConceptRelationshipSabPrefterm], int, Dict[str, str]]
    """
    if connexion.request.is_json:
        concept_sab_rel_depth = ConceptSabRelDepth.from_dict(connexion.request.get_json())  # noqa: E501
    return neo4jManager.concepts_trees_post(concept_sab_rel_depth)


def dataset_get(application_context, data_type=None, description=None, alt_name=None, primary=None, contains_pii=None, vis_only=None, vitessce_hint=None, dataset_provider=None):  # noqa: E501
    """Returns information on a set of HuBMAP or SenNet dataset types, with options to filter the list to those with specific property values. Filters are additive (i.e., boolean AND)

     # noqa: E501

    :param application_context: Required filter to indicate application context.
    :type application_context: str
    :param data_type: Optional filter for data_type
    :type data_type: str
    :param description: Optional filter for display name. Use URL-encoding (space &#x3D; %20).
    :type description: str
    :param alt_name: Optional filter for a single element in the alt-names list--i.e., return datasets for which alt-names includes a value that matches the parameter. Although the field is named &#39;alt-names&#39;, the parameter uses &#39;alt_name&#39;. Use URL-encoding (space &#x3D; %20)
    :type alt_name: str
    :param primary: Optional filter to filter to primary (true) or derived (false) assay.
    :type primary: str
    :param contains_pii: Optional filter for whether the dataset contains Patient Identifying Information (PII). Although the field is named &#39;contains-pii&#39;, use &#39;contains_pii&#39; as an argument.
    :type contains_pii: str
    :param vis_only: Optional filter for whether datasets are visualization only (true). Although the field is named &#39;vis-only&#39;, use &#39;vis_only&#39; as an argument.
    :type vis_only: str
    :param vitessce_hint: Optional filter for a single element in the vitessce_hint list--i.e., return datasets for which vitessce_hints includes a value that matches the parameter. Although the field is named &#39;vitessce-hints&#39;, use &#39;vitessce_hint&#39; as an argument.
    :type vitessce_hint: str
    :param dataset_provider: Optional filter to identify the dataset provider - IEC (iec)  or external (lab)
    :type dataset_provider: str

    :rtype: Union[List[DatasetPropertyInfo], Tuple[List[DatasetPropertyInfo], int], Tuple[List[DatasetPropertyInfo], int, Dict[str, str]]
    """
    return neo4jManager.dataset_get(application_context, data_type, description, alt_name, primary, contains_pii, vis_only, vitessce_hint, dataset_provider)


def semantics_semantic_id_semantics_get(semantic_id):  # noqa: E501
    """Returns a list of semantic_types {queryTUI, querySTN ,semantic, TUI_STN} of the semantic type

     # noqa: E501

    :param semantic_id: The semantic identifier
    :type semantic_id: str

    :rtype: Union[List[QQST], Tuple[List[QQST], int], Tuple[List[QQST], int, Dict[str, str]]
    """
    return neo4jManager.semantics_semantic_id_semantics_get(semantic_id)


def terms_term_id_codes_get(term_id):  # noqa: E501
    """Returns a list of codes {TermType, Code} of the text string

     # noqa: E501

    :param term_id: The term identifier
    :type term_id: str

    :rtype: Union[List[TermtypeCode], Tuple[List[TermtypeCode], int], Tuple[List[TermtypeCode], int, Dict[str, str]]
    """
    return neo4jManager.terms_term_id_codes_get(term_id)


def terms_term_id_concepts_get(term_id):  # noqa: E501
    """Returns a list of concepts associated with the text string

     # noqa: E501

    :param term_id: The term identifier
    :type term_id: str

    :rtype: Union[List[str], Tuple[List[str], int], Tuple[List[str], int, Dict[str, str]]
    """
    return neo4jManager.terms_term_id_concepts_get(term_id)


def terms_term_id_concepts_terms_get(term_id):  # noqa: E501
    """Returns an expanded list of concept(s) and preferred term(s) {Concept, Term} from an exact text match

     # noqa: E501

    :param term_id: The term identifier
    :type term_id: str

    :rtype: Union[List[ConceptTerm], Tuple[List[ConceptTerm], int], Tuple[List[ConceptTerm], int, Dict[str, str]]
    """
    return neo4jManager.terms_term_id_concepts_terms_get(term_id)


def tui_tui_id_semantics_get(tui_id):  # noqa: E501
    """Returns a list of symantic_types {semantic, STN} of the type unique id (tui)

     # noqa: E501

    :param tui_id: The TUI identifier
    :type tui_id: str

    :rtype: Union[List[SemanticStn], Tuple[List[SemanticStn], int], Tuple[List[SemanticStn], int, Dict[str, str]]
    """
    return neo4jManager.tui_tui_id_semantics_get(tui_id)


def valueset_get(parent_sab, parent_code, child_sabs):  # noqa: E501
    """Returns a valueset of concepts that are children (have as isa relationship) of another concept.

     # noqa: E501

    :param parent_sab: the SAB of the parent concept
    :type parent_sab: str
    :param parent_code: the code of the parent concept in the SAB (local ontology)
    :type parent_code: str
    :param child_sabs: the list of SABs for child concepts, in order of preference (in case of parent concepts with cross-references)
    :type child_sabs: List[str]

    :rtype: Union[List[SabCodeTerm], Tuple[List[SabCodeTerm], int], Tuple[List[SabCodeTerm], int, Dict[str, str]]
    """
    return neo4jManager.valueset_get(parent_sab, parent_code, child_sabs)
