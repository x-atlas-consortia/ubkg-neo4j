## Neo4j support for UBKG

This directory contains the files used to create the docker container used to run the UBKG Neo4j instance as well as several support scripts used to run and build the container.

#### Files
 - **Dockerfile** The file containing the instructions of how to build the Docker image.
 - **start.sh** The file used as the final startup when the container is run.  Internal to the image/container.
 - **neo4j.conf** The Neo4j configuration file used to run Neo4j in the container.  Internal to the image/container.
 - **set_constratints.cypher** The file containing a set of Neo4j Cypher instructions to set contstraints and build indices in the UBKG Neo4j database.  Internal to the image/container.
 - **build-local.sh** A shell script that will build the Docker image locally (not pushed to DockerHub).  The image is built and tagged as `ubkg-neo4j-local`.
 - **tag-and-push.sh** A shell script that will tag the locally build image (built with build-local.sh) as `hubmap/ubkg-neo4j:latest` and push to DockerHub.  Before using this script you must log into DockerHub using credentials with write permission to the HuBMAP DockerHub organization using `docker login`.
 - **run-local.sh** A shell script to run the container built by build-local.sh.  This script takes a single argument of the password used to access the database.  The standard UI/bolt ports of 7474/7687 are used and exposed on localhost.  The database username is set to `neo4j` and the directory with csv files for import are expected to be present in the directory `../neo4j/import/` for this script to work.
 - **build-push-multi-arch.sh** A script used to support running on x86 and arm platforms.  Experimental at this point..