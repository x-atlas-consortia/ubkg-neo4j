CALL db.relationshipTypes()
YIELD relationshipType
WHERE NOT (relationshipType CONTAINS '-' OR relationshipType CONTAINS '(' OR relationshipType =~ '^\d.*')
WITH apoc.coll.disjunction(COLLECT(DISTINCT relationshipType),["CODE","ISA_STY","PREF_TERM","DEF","STY"]) AS nosys
MATCH (c:Code)-[r]->()
WITH nosys, COLLECT(DISTINCT(TYPE(r))) AS ttys
WITH ttys, nosys, apoc.coll.disjunction(nosys,ttys) AS cuicuis
UNWIND cuicuis as relationshipType
RETURN relationshipType
ORDER BY relationshipType