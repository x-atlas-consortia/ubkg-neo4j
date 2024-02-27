// Obtains an ordered set of relationship types for relevant relationships between Concept nodes
// in the UBKG (aka "CUI-CUI" relationships).
// Excludes relationship types that have special characters or that start with numbers.
// Excludes relationships that exist between Concept nodes and other types of node (e.g., Code)
CALL db.relationshipTypes()
YIELD relationshipType
WHERE NOT (relationshipType CONTAINS '-' OR relationshipType CONTAINS '(' OR relationshipType CONTAINS ':' OR relationshipType =~ '^\d.*')
WITH apoc.coll.disjunction(COLLECT(DISTINCT relationshipType),["CODE","ISA_STY","PREF_TERM","DEF","STY"]) AS nosys
MATCH (c:Code)-[r]->()
WITH nosys, COLLECT(DISTINCT(TYPE(r))) AS ttys
WITH ttys, nosys, apoc.coll.disjunction(nosys,ttys) AS cuicuis
UNWIND cuicuis as relationshipType
RETURN relationshipType
ORDER BY relationshipType