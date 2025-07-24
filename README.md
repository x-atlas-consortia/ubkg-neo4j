# Unified Biomedical Knowledge Graph (UBKG) 
# Docker Distribution options for the UBKG neo4j

Containerized distribution options for instances of the UBKG are
available from the [UBKG Download](https://ubkg-downloads.xconsortia.org/) site.
Distributions are available as Zip archives.

Distribution types include:
## Turnkey Docker distribution

A turnkey Docker distribution builds a Docker container running an instance of a UBKG neo4j graph database.

Instructions for building a turnkey Docker distribution are in the file README-Docker.md. (_link after merge to main_)

## UBKGBox distribution

**[UBKGBox](https://github.com/x-atlas-consortia/ubkg-box)** is a Docker Compose
multi-container application featuring:
- a **ubkg-back-end** service running an instance of a UBKG context in neo4j
- a **ubkg-front-end** service running a number of UBKG clients, including an instance of ubkg-api.

Instructions for building and publishing the **ubkg-front-end** image are in the ubkg-api repo. (_link after merge_)

Instructions for build the complete UBKGBox instance, including the **ubkg-back-end** service, are in the file 
README - UBKGBOX.md (_link after merge_).