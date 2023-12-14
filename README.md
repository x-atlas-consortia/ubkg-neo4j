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

## Requests for Access
The UBKG contains material extracted from the 
Unified Medical Language System ([UMLS](https://www.nlm.nih.gov/research/umls/index.html)) under license.

UBKG distributions cannot be published to public repositories, such as Github or Dockerhub.

Use of the distribution requires authorization per licensing requirements. 

To obtain access to a UBKG distribution, contact the UBKG steward:

   [Jonathan Silverstein, MD](mailto:j.c.s@pitt.edu)

      
    Jonathan Silverstein, MD
    Department of Biomedical Informatics
    University of Pittsburgh


## Access to distributions
The UBKG is distributed as a Zip file stored in a private collection in
[Globus](https://www.globus.org/). Downloading the distribution 
requires a Globus account.

Because of the size of the distribution, the use of [Globus Connect Personal](https://www.globus.org/globus-connect-personal)
is recommended for downloading.

# Instructions
- [Instructions for deploying a distribution](/docs/DEPLOYMENT INSTRUCTIONS.md)
- [Instructions for building a new distribution](/docs/BUILD INSTRUCTIONS.md)






