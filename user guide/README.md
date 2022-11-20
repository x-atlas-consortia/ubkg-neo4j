# User Guide
Adding assertions to the Unified Biomedical Knowledge Graph (UBKG)

# Objectives
This guide describes how to format assertions as an ontology so that the ontology can be added to the Unified Biomedical Knowledge Graph database. The guide includes recommendations for optimizing and deepening the integration of an ontology into the UBKG to establish new relationships among entities and cross-references among ontologies.

# Audience
This guide is intended for users who are subject matter experts in what biomedical assertions they might want to represent (e.g., genes and their products), as an ontology, but not necessarily conversant with either ontological concepts or knowledge graphs.

[Concepts.md](https://github.com/dbmi-pitt/UBKG/blob/main/user%20guide/Concepts.md) describes terms that this guide uses that are relevant to ontologies or knowledge graphs. 

# Guiding Principles for Integration
An important goal of the UBKG is to establish connections between ontologies. For example,if information on the relationships between proteins and genes described in one ontology can be connected to information on the relationships between genes and diseases described in another ontology, it may be possible to identify previously unknown relationships between proteins and diseases.

If the UBKG is to connect ontologies, the ontologies should, as much as possible, represent their entities and relationships similarly. **_To the degree possible_**,
1. Entities should be encoded with codes from published biomedical ontologies and vocabularies. For example, genes should be encoded in a standard vocabulary such as HGNC.
2. Relationships should be represented with properties from the Relationship Ontology.
3. Codes for entities should be cross-referenced to UMLS CUIs.

# Integration Options
An ontology can be integrated into the UBKG from one of the following sources:
1. An OWL file that follows OBO principles. If the OWL file is published online, only the URL to the OWL is needed.
2. A set of UBKG ingest files. 

The rest of this guide focuses on ingest files.

# Ingest Files and Content
A set of UBKG ingest files describes the entities and relationships of an ontology that is to be integrated into the UBKG. 

An ingest file set consists of two Tab-Separated Variables (TSV) files:

- **edges.tsv**: Describes the triples comprising the ontology
- **nodes.tsv**: Describes metadata for entities

This file provides added detail for OPTIONAL Data Distillery fields and examples, beyond the general UBKG requirements for which this guide is written.
