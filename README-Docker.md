# Unified Biomedical Knowledge Graph (UBKG) 
# Docker neo4j Distribution

The **ubkg-neo4j** repository contains infrastructure to build and deploy a Docker distribution
of a UBKG instance running with version 5 of neo4j. The Docker distribution eliminates the need to 
have a local installation of neo4j.

The UBKG distribution takes advantage of improvements to neo4j indexing that were 
introduced in version 5, including relationship indexes.

UBKG distributions are provided as Zip archives.

## Supported platforms
The distribution was developed and tested on the following platforms:
- Mac OSX with M1 processors
- Linux with x86-64 arcitecture

The distribution should also work on the following platforms:
- Max OSX with Intel or M2 processors
- a Linux release supported by Docker
 
A PowerShell version of the distribution shell script for Windows will be developed if necessary.

## Obtaining a distribution

### Licensing
The UBKG contains material extracted from the 
Unified Medical Language System ([UMLS](https://www.nlm.nih.gov/research/umls/index.html)) under license.

UBKG distributions cannot be published to public repositories, such as Github or Dockerhub. Use of the distribution requires authorization per licensing requirements. 

### Downloading
Distributions of various UBKG contexts are available at the [UBKG Download](https://ubkg-downloads.xconsortia.org/) site. A UMLS API Key is required to download distribution files.

# Instructions
- [Instructions for deploying a distribution](docs/DEPLOYMENT_INSTRUCTIONS.md)
- [Instructions for building a new distribution](docs/BUILD_INSTRUCTIONS.md)






