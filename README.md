# Unified Biomedical Knowledge Graph (UBKG)
## neo4j Ontology Knowledge Graph

The components of the UBKG include:

- The source framework that extracts ontology information from the UMLS to create a set of CSV files (**UMLS CSVs**)
- The generation framework that appends to the UMLS CSVs assertion data from other ontologies to create a set of **ontology CSVs**
- A neo4j  **ontology knowledge graph** populated from the ontology CSVS.
- An **API server** that provides RESTful endpoints to query the ontology knowledge graph.

This repository contains the source that will build and instantiate 
a Docker container for the neo4j host of the ontology knowledge graph.
---

# Building and instantiating a new UBKG instance
1. Obtain a set of **ontology CSV files** that will be imported into a graph database in the neo4j instance. (To generate a new set of ontology CSVs, use scripts in the source and generation frameworks, in the [ubkg-etl](https://github.com/x-atlas-consortia/ubkg-etl) repository.)
2. Copy the ontology CSVs to the neo4j/import path of the local clone of this repository.
3. Run the script **run.sh** in the docker path of the local clone of the repository, with parameters as described below.

## Parameters for run.sh


| Parameter name | required | Description                                                                        | Default  |
|----------------|----------|------------------------------------------------------------------------------------|----------|
| p              | yes      | password for the neo4j account                                                     |          |
| u              |no| the username used to connect to the neo4j database                                 | neo4j    |
| c              |no| the path to the directory in the local repository containing the ontology CSV files | neo4j/import |
| n              |no| the port to expose the **neo4j browser/UI** on                                     |7474|
| b              |no| the port to expose the **neo4j/bolt://** interface on                              |7687|     
| h              |no|help||

Parameters are options--i.e., not positional.

### Examples
```
./run.sh -p pwd
```
Creates a Docker container for an ontology database with password **pwd**, with defaults for all other parameters.
```
./run.sh -p pwd -u george -n 9988 
```
Creates a Docker container for an ontology database with an account named **george** with password **pwd**, with the browser port of **9988**.
## run.sh actions
The **run.sh** script will:
1. Obtain a neo4j image from DockerHub.
2. Copy the ontology CSVs from the neo4j/import path of the local repo to the image.
3. Execute the Dockerfile in the docker path of the local repository.

## Dockerfile actions
The Dockerfile will:
1. Instantiate a Docker container running neo4j.
2. Populate a database named **ontology** [^1] in the neo4j instance by importing from the ontology CSVs.
3. Set the password for the **neo4j** account of the neo4j instance.
4. Expose ports for the Dockerized neo4j instance.
5. Set constraints for the **ontology** database.
6. Set the **ontology** database to read-only.

[^1]The neo4j database must be named **ontology**. The ubkg API expects to connect to a neo4j database with that name.

# Dependencies
1. The machine that hosts the local repository must be running Docker.
2. A complete set of ontology CSVs must be in the neo4j/import path of the local repository.

# Files in the set of ontology CSVs 
1. CODE-CUIs.csv 
2. CODEs.csv 
3. CUI-CODEs.csv 
4. CUI-CUIs.csv 
5. CUI-SUIs.csv
6. CUI-TUIs.csv
7. CUIs.csv
8. DEFrel.csv
9. DEFs.csv
10. SUIs.csv
11. TUIrel.csv
12. TUIs.csv
