/*

Query to create "collapsed concept subgraph" properties for Concept nodes in a UBKG instance.

A "concept subgraph" is the subgraph that originates from a Concept node, involving all of the
Code, Term, Semantic, and Definition nodes that associate with the Concept.

The "collapsed concept subgraph" property is a representation of the concept subgraph as a JSON string.

The difference between the conceptsubgraph property created by this version of the query and the
property created by add_collapsed_concept_subgraph_property.cypher is
that the concept-code mappings are not limited to the "primary cross-reference" codes.

To maximize code-concept synonymy in the UBKG, a code from a SAB should be linked to a concept that has the highest possible number of links to other codes. When a code is imported into the UBKG, the default action is to link the code a new concept that corresponds to the code: e.g., the code with CodeID="SAB1:X" is linked to a concept with CUI="SAB1:X CUI". This default action can be overridden by "cross-referencing" the code to another concept.

A code can cross-reference a concept by CUI or a code. A cross-referenced code is usually from another SAB: e.g., in the MP SAB, code MP:0002274 is cross-referenced to FMA:62500. During ETL, the cross-reference to a code is resolved to the CUI for the concept linked to the cross-referenced code. For example, MP:0002274's cross-reference to FMA:62500 is resolved to FMA:62500's CUI (C0225699).

Cross-references can be complicated in the UBKG.

For example:
1. A code can have multiple cross-references--i.e., the code-concept arrangement is one to many. For example, in MP, MP:0002274 is cross-referenced to both FMA:62500 and CL:0002062.
2. Multiple codes from the same SAB can cross-reference the same code or concept--i.e., the code-concept is many to one. For example, in MP, codes. For example, in MP, the codes MP:0008047, MP:0008054, MP:0008876, MP:0009099, and MP:0009394 all cross-reference CL:0002343.
3. A code can have a "transitive" cross reference, in which a cross-referenced code itself has a cross-reference. For example, in MONDO, MONDO:0001155 cross-references DOID:10927. In DOID, DOID:10927 cross-references C0156042; thus, MONDO:0001155 has a transitive cross-reference to C0156042.

The UBKG ETL assigns one code in each non-UMLS SAB to be the "primary cross-reference code" to a CUI. The ETL's algorithm assigns primary cross-reference CUIs in the following order of preference:
1. A cross-referenced UMLS CUI
2. A UMLS CUI of a cross-referenced code
3. A CUI of a cross-referenced code from a non-UMLS SAB
4. A CUI that corresponds to the code ID + 'CUI'

The UBKG ETL may assign other cross-references to a code; however, these other cross-references are secondary. The use of a primary cross-reference for a code mitigates the risk of duplication in queries that return codes associated with concepts.


*/

// For each Concept node with id in the parameter ids, obtain information from the subgraph.
MATCH (n:Concept) WHERE id(n) IN $ids

WITH n
// 1. the preferred term for the Concept
OPTIONAL MATCH (n)-[:PREF_TERM]->(t:Term)
// 2. the set of Code nodes linked to the Concept, along with the Terms linked to the Codes
OPTIONAL MATCH (n)-[:CODE]->(c:Code)-[tty]->(ct:Term)
// 3. the set of Definitions for the Concept
OPTIONAL MATCH (n)-[:DEF]->(d:Definition)
// 4. the set of Semantic Types for the Concept
OPTIONAL MATCH (n)-[:STY]->(s:Semantic)

// Build the conceptsubgraph object.

// 1. Collect "term objects" per code. A "term object" includes CUI of each term. The CUI of the terms of the primary cross-reference
// match the concept CUI.
WITH n, t, d, s, c, COLLECT(DISTINCT CASE WHEN ct.name IS NULL THEN NULL ELSE {name:ct.name, tty:Type(tty), ttyCUI:tty.CUI} END) AS termsPerCode

// 2. Build the codes array. Each member of the array has keys for codeid, sab, terms (without ttyCUI) and the computed primary flag.
WITH n, t, d, s,
COLLECT(DISTINCT CASE WHEN c.CodeID IS NULL THEN NULL ELSE
{
	codeid: c.CodeID,
	sab: c.SAB,
	primary: CASE WHEN ANY(x IN termsPerCode WHERE x IS NOT NULL AND x.ttyCUI = n.CUI) THEN true ELSE false END,
	terms: [tt IN termsPerCode WHERE tt IS NOT NULL | {name: tt.name, tty: tt.tty}]
} END) AS codes,


//3. Build the definitions array.
COLLECT (DISTINCT CASE WHEN d.DEF IS NULL THEN NULL ELSE {def: d.DEF, sab: d.SAB} END) AS defs,

//4. Build the semantic types array.
COLLECT (DISTINCT CASE WHEN s.name IS NULL THEN NULL ELSE {sty: s.name, tui: s.TUI, def: s.DEF, stn: s.STN} END) AS stys

// Build final conceptsubgraph object and set as a property of the concept node.

WITH n, {cui: n.CUI, pref_term: t.name, codes: codes, definitions: defs, semantic_types: stys} AS conceptsubgraph

// Ensure we handle a missing codes array safely
UNWIND coalesce(conceptsubgraph.codes, []) AS code

// Order so primary=true come first, then by codeid
WITH n,conceptsubgraph, code
ORDER BY CASE WHEN code.primary = true THEN 0 ELSE 1 END, coalesce(code.codeid, '') ASC

// Re-collect codes in the desired order
WITH n, collect(code) AS orderedCodes, conceptsubgraph

// Rebuild the map with the ordered codes array
WITH n, {cui: conceptsubgraph.cui, pref_term: conceptsubgraph.pref_term, codes: orderedCodes, definitions: conceptsubgraph.definitions, semantic_types: conceptsubgraph.semantic_types} AS conceptsubgraph
SET n.conceptsubgraph = apoc.convert.toJson(conceptsubgraph) RETURN COUNT(n) AS processed

