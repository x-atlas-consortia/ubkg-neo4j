# Docker Deployment of UBKG neo4j

This directory contains the files used to create the docker container used to run the UBKG Neo4j instance as well as several support scripts used to run and build the container.

For details on Docker deployment, consult the README.md at the root of this respository.

## Deployment files
|File| Description                                                                                      |Scope|
|---|--------------------------------------------------------------------------------------------------|---|
|**run.sh**| Script that builds the UBKG Docker container                                                     |Global|
|**Dockerfile**| Instructions for building the container                                                          |Internal|
|**neo4j.conf**| Configuration file for the neo4j instance                                                        |Internal|
|**set_constraints.cypher**| Set of neo4j Cypher instructions to set constraints and build indices in the UBKG Neo4j database |Internal|
|**start.sh**| Script that populates the ontology database in neo4j from the ontology CSVs|internal|                                                                          
 

## Developer Files
|File| Description                                                                                      |
|---|--------------------------------------------------------------------------------------------------|
|**build-local.sh**|Builds the Docker image locally (not pushed to DockerHub).  The image is built and tagged as `ubkg-neo4j-local`.|
|**run-local.sh**|run the container built by build-local.sh.  This script takes a single argument of the password used to access the database.  The standard UI/bolt ports of 7474/7687 are used and exposed on localhost.  The database username is set to `neo4j` and the directory with csv files for import are expected to be present in the directory `../neo4j/import/` for this script to work.|
|**build-push-multi-arch.sh** | Builds an image on x86 and arm platforms.  Experimental at this point.|