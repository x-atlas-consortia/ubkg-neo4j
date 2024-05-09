// Obtains an ordered set of relationship types for relevant relationships between Code nodes and
// other nodes in the UBKG (aka TUI relationships).
MATCH (c:Code)-[r]->()
RETURN DISTINCT TYPE(r) as relationshipType
ORDER BY relationshipType

