# Docker Deployment of UBKG neo4j

This directory contains the files needed to create the Docker images used to run the UBKG Neo4j container. Docker images supporting both x86-64 and arm64 platforms are built. For details on Docker using this image to host the UBKG in Neo4j, consult the [README.md](https://github.com/x-atlas-consortia/ubkg-neo4j/blob/main/README.md) at the root of this respository.

## Requirements
  - [Docker must be installed](https://docs.docker.com/engine/install/) with Docker BuildX build support.  By default Docker BuildX support is installed with Docker Desktop.  If you have a version of Docker installed without Desktop you can [install Docker BuildX manually](https://docs.docker.com/build/install-buildx/).
  - The bash shell scripts contained in this directory are intended for use on Mac OS X or Linux.  These scripts will not work on Windows. (The resulting Docker images will, however, run on Windows.)

## Build Scripts
#### build-push-multi-arch.sh
The build-push-multi-arch.sh script is a bash script which will build and push to DockerHub the UBKG Neo4j Docker images with support for both x86-64 and amd64 platforms. The script takes advantage of the Docker Buildx `build --platform` option to create the multi-platform images.

Before running this script first log into DockerHub with the `docker login` command using an account that has write privileges in the HuBMAP DockerHub Organization.

usage: ./build-push-multi-arch.sh [-rv version]
If run without the `-rv` option the script will build the multi-platform images and push them to DockerHub with the tag `hubmap/ubkg-neo4j:latest`.
If given the `-rv <version` argument the script will build the multi-platrom images and push them to DockerHub with the addional tags of `hubmap/ubkg-neo4j:current-release` and `hubmap/ubkg-neo4j:<version>`, where <versions> is replaced with the version entered as the version argument.

e.g. `./build-push-multi-arch.sh -rv 3.2.4`

#### build-local.sh
usage: ./build-local.sh

The build-local.sh simply builds a local image for use during development and debugging of the UBKG Neo4j Docker container. The locally built image will be tagged as `ubkg-neo4j-local`  To run the local image use the [run.sh]() script at the top level directory in this repository with the arguments `-t local`.

## Files used for image build
|File| Description                                                                                      |Scope|
|---|--------------------------------------------------------------------------------------------------|---|
|**Dockerfile**| Instructions for building the container                                                          |Build file|
|**neo4j.conf**| Configuration file for the neo4j instance                                                        |Added to image|
|**set_constraints.cypher**| Set of neo4j Cypher instructions to set constraints and build indices in the UBKG Neo4j database |added to image|
|**start.sh**| Script that populates the ontology database in neo4j from the ontology CSVs|Added to image|

## Support Scripts
|File| Description                                                                                      |
|---|--------------------------------------------------------------------------------------------------|
|**build-local.sh**|Builds the Docker image locally (not pushed to DockerHub).  The image is built and tagged as `ubkg-neo4j-local`.|
|**build-push-multi-arch.sh** | Builds images for x86-64 and arm64 platforms and pushes the images to DockerHub.|

