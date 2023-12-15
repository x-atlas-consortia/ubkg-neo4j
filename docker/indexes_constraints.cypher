MATCH (n:Term) WHERE count{(n)--()}=0 DELETE (n);
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.TUI IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.STN IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.DEF IS UNIQUE;
CREATE CONSTRAINT FOR (n:Semantic) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT FOR (n:Concept) REQUIRE n.CUI IS UNIQUE;
CREATE CONSTRAINT FOR (n:Code) REQUIRE n.CodeID IS UNIQUE;
CREATE INDEX FOR (n:Code) ON (n.SAB);
CREATE INDEX FOR (n:Code) ON (n.CODE);
CREATE INDEX FOR (n:Term) ON (n.name);
CREATE INDEX FOR (n:Definition) ON (n.SAB);
CALL db.relationshipTypes()
YIELD relationshipType
WHERE NOT (relationshipType CONTAINS '-' OR relationshipType =~ '^\d.*')
WITH apoc.coll.disjunction(COLLECT(relationshipType),["CODE","ISA_STY","PREF_TERM","DEF","STY"]) AS nosys
MATCH (c:Code)-[r]->()
WITH nosys, COLLECT(DISTINCT(TYPE(r))) AS ttys
WITH ttys, nosys, apoc.coll.disjunction(nosys,ttys) AS cuicuis
WITH ttys, cuicuis
CALL {
WITH ttys, cuicuis
WITH apoc.text.join([x in cuicuis | x ], '|') AS relationshipTypes
CALL apoc.cypher.runSchema("CREATE FULLTEXT INDEX r_SAB FOR ()-[r:"+relationshipTypes+"]-() ON EACH [r.SAB]",{})
YIELD value
RETURN value AS irrelevant
UNION
WITH ttys, cuicuis
UNWIND cuicuis as relationshipType
CALL apoc.cypher.runSchema("CREATE INDEX rSAB_"+relationshipType+" FOR ()-[r:"+relationshipType+"]->() ON (r.SAB)", {})
YIELD value
RETURN value AS irrelevant
UNION
WITH ttys, cuicuis
UNWIND ttys as relationshipType
CALL apoc.cypher.runSchema("CREATE INDEX rCUI_"+relationshipType+" FOR ()-[r:"+relationshipType+"]->() ON (r.CUI)", {})
YIELD value
RETURN value AS irrelevant
}
RETURN irrelevant

