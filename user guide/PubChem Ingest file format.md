# PubChem Ingest File format

# edges.tsv

Field|Corresponding element in UBKG|Accepted formats|Examples
---|---|---|---
subject|**Code** node|PUBCHEM _PubChem CID_|[PUBCHEM 9549299](https://pubchem.ncbi.nlm.nih.gov/compound/9549299
predicate|relationships|For hierarchical relationships, the IRI http://www.w3.org/2000/01/rdf-schema#subClassOf OR the string “isa”| http://www.w3.org/2000/01/rdf-schema#subClassOf 
 | | |For non-hierarchical relationships, an IRI for a relationship property in RO	|http://purl.obolibrary.org/obo/RO_0002292
 | | |Custom string | drinks milkshake of
 object|**Code** node|same as for subject
 
 # Relationships (predicates)
 The definition of relationships is the principle informatics task of assertion. An appropriate selection of concept in the _node_dbxrefs_ field of **nodes.tsv** will associate cross-referenced assertions.
 
 ## An example for PUBCHEM 9549299:
 
 An EGFR inhibitor inhibits the expression of EGFR (UNIPROTKB ID P00533), so a possible assertion is
 
 subjecy | predicate | object
--- | --- | ---
PUBCHEM 9549299 | http://purl.obolibrary.org/obo/RO_0002449 | UNIPROTKB P00533
1 | 2 | 3
 
 RO_0002449 = _directly inhibits_
 
 Because UNIPROTKB is already integrated into the UBKG, any relationship with P00533 would also get the link to HGNC 3236:
 
 ![image](https://user-images.githubusercontent.com/10928372/203175673-0372303c-ac5c-4122-bb6f-74a4dc31903a.png)

 
 # nodes.tsv

## Fields
Field|Corresponding element in UBKG|Accepted formats|Examples
---|---|---|---
node_id|**Code** node|PUBCHEM _PubChem CID_|[PUBCHEM 9549299](https://pubchem.ncbi.nlm.nih.gov/compound/9549299
node_label|**Term** node, _Preferred Term_ (PT) relationship|Text string for the **Compound Name**| EGFR Inhibitor
node_definition (_optional_)|**Definition** node, _DEF_ relationship |Text string - IUPAC Name?|N-[3-[[6-[3-(trifluoromethyl)anilino]pyrimidin-4-yl]amino]phenyl]cyclopropanecarboxamide
node_synonyms (_optional_)|**Term** node; _Synonym_ (SYN) relationship|**Pipe-delimited** list of synonyms|See example (pipes are also used to format table cells)
node_dbxrefs (_optional_)|Cross-references|Pipe-delimited list of references to cross-referenced concepts. Each cross-reference should be in format SAB:code or UMLS:CUI |UMLS:C5574906

### Example of synonyms for EGFR inhibitor
N-[3-[[6-[3-(trifluoromethyl)anilino]pyrimidin-4-yl]amino]phenyl]cyclopropanecarboxamide|1S/C21H18F3N5O/c22-21(23,24)14-3-1-4-15(9-14)27-18-11-19(26-12-25-18)28-16-5-2-6-17(10-16)29-20(30)13-7-8-13/h1-6,9-13H,7-8H2,(H,29,30)(H2,25,26,27,28)|YOHYSYJDKVYCJI-UHFFFAOYSA-N|C1CC1C(=O)NC2=CC=CC(=C2)NC3=NC=NC(=C3)NC4=CC=CC(=C4)C(F)(F)F

i.e.,
2.1.1IUPAC Name|2.1.2InChI|2.1.3InChIKey|2.1.4Canonical SMILES
