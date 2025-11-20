// Query to create "collapsed concept subgraph" properties for Concept nodes in a UBKG instance.

// A "concept subgraph" is the subgraph that originates from a Concept node, involving all of the
// Code, Term, Semantic, and Definition nodes that associate with the Concept.

// The concept subgraph for a concept can be "collapsed" to a property that is a JSON string.

// For each Concept node with id in the parameter ids, obtain information from the subgraph.
MATCH (n:Concept) WHERE id(n) IN $ids

WITH n
// 1. the preferred term for the Concept
OPTIONAL MATCH (n)-[:PREF_TERM]->(t:Term)
// 2. the set of Codes linked to the Concept
OPTIONAL MATCH (n)-[:CODE]->(code:Code)
// 3. the set of Term Types linked to the Codes for the Concept
OPTIONAL MATCH (n)-[:CODE]->(c:Code)-[tty]->(ct:Term) WHERE tty.CUI = toString(n.CUI)
// 4. the set of Definitions for the Concept
OPTIONAL MATCH (n)-[:DEF]->(d:Definition)
// 5. the set of Semantic Types for the Concept
OPTIONAL MATCH (n)-[:STY]->(s:Semantic)

// Build the "Concept node" object.

// 1. Create Terms object - array of objects representing the Term nodes for the Code nodes that link to Concept nodes.
WITH n,t,c,d,s,collect(DISTINCT CASE WHEN ct.name IS NULL THEN NULL ELSE {name:ct.name,tty:Type(tty)} END) AS terms

// 2. Create Codes object - array of objects representing Code nodes that link to Concept nodes.
//    The Terms object will be a key of the Codes object.
WITH n,t,d,s, collect(DISTINCT CASE WHEN c.CodeID IS NULL THEN NULL ELSE {codeid:c.CodeID,sab:c.SAB,terms:terms} END) AS codes,

// 3. Create Definitions object - array of objects representing Definition nodes that link to Concept nodes.
collect(DISTINCT CASE WHEN d.DEF IS NULL THEN NULL ELSE{def:d.DEF,sab:d.SAB} END) AS defs,

// 4. Create Semantic Types object - array of objects representing Semantic Type nodes that link to Concepts nodes.
collect(DISTINCT CASE WHEN s.name IS NULL THEN NULL ELSE {sty:s.name,tui:s.TUI,def:s.DEF,stn:s.STN} END) AS stys

// Consolidate Codes, Definitions, and Semantic Types objects into an object representing the Concept subgraph.
WITH n, {cui:n.CUI,pref_term:t.name,codes:codes,definitions:defs,semantic_types:stys} AS conceptsubgraph
SET n.conceptsubgraph=apoc.convert.toJson(conceptsubgraph)
RETURN COUNT(n) AS processed