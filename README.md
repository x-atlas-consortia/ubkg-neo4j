# UBKG
The **Unified Biomedical Knowledge Graph (UBKG)** is a [knowledge graph](https://en.wikipedia.org/wiki/Knowledge_graph) database that represents a set of interrelated concepts from biomedical ontologies and vocabularies. The UBKG combines information from the National Library of Medicine's [Unified Medical Language System](https://www.nlm.nih.gov/research/umls/index.html) (UMLS) with [_assertions_](https://www.w3.org/TR/owl2-syntax/#Assertions) from “non-UMLS” ontologies or vocabularies, including:
- Ontologies published in references such as the [NCBO Bioportal](https://bioportal.bioontology.org/) and the [OBO Foundry](https://obofoundry.org/).
- Custom ontologies derived from data sources such as [UNIPROTKB](https://www.uniprot.org/).
- Other custom ontologies, such as those for the [HuBMAP](https://hubmapconsortium.org/) platform.

An important goal of the UBKG is to establish connections between ontologies. For example,if information on the relationships between _proteins_ and _genes_ described in one ontology can be connected to information on the relationships between _genes_ and _diseases_ described in another ontology, it may be possible to identify previously unknown relationships between _proteins_ and _diseases_.

## Components and generation frameworks
The primary components of the UBKG are:
- a graph database, deployed in [neo4j](https://neo4j.com/)
- a [REST API](https://restfulapi.net/) that provides access to the information in the graph database

The UBKG database is populated from the load of a set of CSV files, using [**neo4j-admin import**] (https://neo4j.com/docs/operations-manual/current/tutorial/neo4j-admin-import/). The set of CSV import files is the product of two _generation frameworks_. 

### Source framework
The base set of nodes (entities) and edges (relationships) of the UBKG graph are obtained by converting information from the UMLS. 
- Information on the concepts in the ontologies and vocabularies that are integrated into the UMLS Metathesaurus can be downloaded using the [MetamorphoSys](https://www.ncbi.nlm.nih.gov/books/NBK9683/#:~:text=MetamorphoSys%20is%20the%20UMLS%20installation,to%20create%20customized%20Metathesaurus%20subsets.) application. 
- Additional semantic information related to the UMLS can be downloaded manually from the [Semantic Network](https://lhncbc.nlm.nih.gov/semanticnetwork/). 

The result of the downloads is a set of files in [Rich Release Format](https://www.ncbi.nlm.nih.gov/books/NBK9685) (RRF). The RRF files contain information on source vocabularies or ontologies, codes, terms, and relationships both with other codes in the same vocabularies and with UMLS concepts.

The RRF files are loaded into a data mart. SQL scripts then perform Extraction, Transformation, and Loading of the RRF data into a set of twelve tables. These tables are then exported to CSV format to become the **UMLS CSVs***.



