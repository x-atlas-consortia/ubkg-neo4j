# Unified Biomedical Knowledge Graph (UBKG)
## neo4j Ontology Knowledge Graph

The components of the UBKG include:

- The **source framework** that extracts ontology information from the UMLS to create a set of CSV files (**UMLS CSVs**)
- The **generation framework** that appends to the UMLS CSVs assertion data from other ontologies to create a set of **ontology CSVs**
- A neo4j  **ontology knowledge graph** populated from the ontology CSVs.
- An **API server** that provides RESTful endpoints to query the ontology knowledge graph.

For more details on the UBKG, consult the [documentation](https://ubkg.docs.xconsortia.org/).

This repository contains the source to deploy the ontology knowledge graph as a Docker container.

---
# Licensing restrictions on ontology CSV files
The ontology CSV files contain licensed content extracted from the Unified Medical Language System ([UMLS](https://www.nlm.nih.gov/research/umls/index.html). The ontology CSV files cannot be published to public repositories, such as Github or Dockerhub.

# Dependencies
1. The machine that hosts the local repository must be running Docker.
2. The account that executes the run.sh script must be logged in to Docker Hub.
2. A complete set of ontology CSVs must be path associated with the **c** option. The default path is the **/neo4j/import** folder of this repo; other paths can be specified with the **-c** option.

# Deployment machine
The deployment was developed and tested using Macbook Pros based on the M1 chipset. 
Scripts assume that the host machine is running Mac OSX or Linux.


## Files in the set of ontology CSVs 
1. CODE-SUIs.csv
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

---

# Generating a UBKG neo4j Docker container

Create a Docker container for a neo4j instance of the UBKG by supplying a set of ontology CSVs to a Docker image published in Docker Hub.

1. Clone this GitHub repository (ubkg-neo4j).
2. Obtain a set of **ontology CSV files** that will be imported into a graph database in the neo4j instance. (Generate a new set of ontology CSVs by using the scripts of the UBKG source and generation frameworks, as described in the [ubkg-etl](https://github.com/x-atlas-consortia/ubkg-etl) repository.))
3. Copy the ontology CSVs to the **neo4j/import** path of the local clone of this repository.
4. Log in to [Docker Hub](https://hub.docker.com/).
5. Start Docker on the local repository's host machine.
6. Run the script **run.sh** in the **docker** path of the local clone of the repository, with parameters as described below.

## Connecting to the container
To connect to the container,
1. Start a browser.
2. Point the browser to the machine and port associated with the container.
3. Change to the bolt connection in the Connect URL.
4. Specify the bolt port.
5. Supply connection information for the neo4j user.

## Parameters for run.sh

Parameters are specified as options--i.e., in format

```
-<option letter> <value>
```

All optional parameters have default values.

| Parameter option | required | Description                                                                         | Default      |
|------------------|----------|-------------------------------------------------------------------------------------|--------------|
| p                | yes      | password for the neo4j account                                                      |              |
| d                | no       | name of the neo4j Docker container                                                  | ubkg-neo4j   |
| u                | no       | the username used to connect to the neo4j database                                  | neo4j        |
| c                | no       | the path to the directory in the local repository containing the ontology CSV files | neo4j/import |
| n                | no       | the port to expose the **neo4j browser/UI** on                                      | 7474         |
| b                | no       | the port to expose the **neo4j/bolt://** interface on                               | 7687         |     
| h                | no       | help                                                                                ||


### Examples
```
./run.sh -p pwd
```
Creates a Docker container for an ontology database with password **pwd**, with defaults for all other parameters.
```
./run.sh -p pwd -u bob -n 9988 -d linda
```
Creates a Docker container named **linda** for an ontology database with an account named **bob** with password **pwd**, with the browser port of **9988**.

## run.sh actions
The **run.sh** script will:
1. Create a Docker container on the host machine from the UBKG neo4j image in DockerHub.
2. Populate a knowledge graph database in the neo4j instance named **ontology** using the ontology CSVs from the neo4j/import path of the local github repository.
3. Set constraints on the ontology database and make it read-only.

![img.png](img.png)


# Example output of script.

The script was called on the local machine with options:

| option |description|value|
|--------|---|---|
|p|password|test|
|d|name of container|ubkg-test|
|n|browser port|4000|
|b|bolt port|4500|

```
jas971@jas971s-MBP docker % ./run.sh -p test -d ubkg-test -n 4000 -b 4500

```

## Validation
The script:
- validates parameters
- confirms that a full set of ontology CSV files are available

```
**********************************************************************
All 12 required ontology CSV files were found in directory '/Users/jas971/PycharmProjects/pythonProject/ubkg-neo4j/neo4j/import'.

A Docker container for a neo4j instance will be created using the following parameters:
  - container name:  ubkg-test
  - neo4j account name: neo4j
  - neo4j account password: test
  - CSV directory for ontology CSV files: /Users/jas971/PycharmProjects/pythonProject/ubkg-neo4j/neo4j/import
  - neo4j browser/UI port: 4000
  - neo4j bolt port: 4500
```

## Building the Docker container

```
**************
Starting Docker container
Unable to find image 'hubmap/ubkg-neo4j:latest' locally
latest: Pulling from hubmap/ubkg-neo4j
7eb8632fc2b2: Pull complete 
9867c91448cc: Pull complete 
6fc50df23d40: Pull complete 
d8ea0c28c24a: Pull complete 
3d649c50064c: Pull complete 
4f4fb700ef54: Pull complete 
cd01416a9c68: Pull complete 
ebdc6c133b65: Pull complete 
Digest: sha256:3504a5fcf1ad86a804c442b58d6425b07d116e7eed959cfbdda01dd768e8af11
Status: Downloaded newer image for hubmap/ubkg-neo4j:latest
```

## Import of ontology CSV files
```
*****************************
Ontology neo4j start script
NEO4J_USER: neo4j
Setting the neo4j password as the value of NEO4J_PASSWORD environment variable: test
Changed password for user 'neo4j'.
Importing database from CSV files
neo4j 4.2.5
VM Name: OpenJDK 64-Bit Server VM
VM Vendor: Red Hat, Inc.
VM Version: 11.0.18+10-LTS
JIT compiler: HotSpot 64-Bit Tiered Compilers
VM Arguments: [-XX:+UseParallelGC, -Dfile.encoding=UTF-8]
Neo4j version: 4.2.5
Importing the contents of these files into /usr/src/app/neo4j/data/databases/ontology:
Nodes:
  [Concept]:
  /usr/src/app/neo4j/import/CUIs.csv

  [Semantic]:
  /usr/src/app/neo4j/import/TUIs.csv

  [Definition]:
  /usr/src/app/neo4j/import/DEFs.csv

  [Term]:
  /usr/src/app/neo4j/import/SUIs.csv

  [Code]:
  /usr/src/app/neo4j/import/CODEs.csv

Relationships:
  /usr/src/app/neo4j/import/CUI-CUIs.csv
  /usr/src/app/neo4j/import/CODE-SUIs.csv

  CODE:
  /usr/src/app/neo4j/import/CUI-CODEs.csv

  DEF:
  /usr/src/app/neo4j/import/DEFrel.csv

  STY:
  /usr/src/app/neo4j/import/CUI-TUIs.csv

  ISA_STY:
  /usr/src/app/neo4j/import/TUIrel.csv

  PREF_TERM:
  /usr/src/app/neo4j/import/CUI-SUIs.csv


Available resources:
  Total machine memory: 7.667GiB
  Free machine memory: 5.454GiB
  Max heap memory : 1.705GiB
  Processors: 5
  Configured max memory: 5.366GiB
  High-IO: true

Type normalization:
  Property type of 'value' normalized from 'float' --> 'double' in /usr/src/app/neo4j/import/CODEs.csv
  Property type of 'lowerbound' normalized from 'float' --> 'double' in /usr/src/app/neo4j/import/CODEs.csv
  Property type of 'upperbound' normalized from 'float' --> 'double' in /usr/src/app/neo4j/import/CODEs.csv
Nodes, started 2023-04-03 19:52:56.999+0000
[*Nodes:0B/s 1.160GiB-------------------------------------------------------------------------]21.2M ∆1.45M
Done in 30s 393ms
Prepare node index, started 2023-04-03 19:53:27.397+0000
[*DEDUPLICATE:1.240GiB------------------------------------------------------------------------]87.0M ∆44.5M
Done in 6s 272ms
DEDUP, started 2023-04-03 19:53:33.705+0000
[*DEDUP---------------------------------------------------------------------------------------]    0 ∆    0
Done in 169ms
Relationships, started 2023-04-03 19:53:33.876+0000
[*Relationships:0B/s 1.240GiB-----------------------------------------------------------------]55.8M ∆1.25M
Done in 1m 32s 353ms
Node Degrees, started 2023-04-03 19:55:06.316+0000
[*>(3)===========================================================|CALCULATE:1.194GiB----------]55.8M ∆10.0M
Done in 2s 259ms
Relationship --> Relationship 1-1791/1791, started 2023-04-03 19:55:08.649+0000
[>------------------------------|*LINK(2)=======================|v:150.9MiB/s-----------------]55.8M ∆4.26M
Done in 12s 82ms
RelationshipGroup 1-1791/1791, started 2023-04-03 19:55:20.746+0000
[*>:??---------------------------------------------------------------------------|v:??--------]3.05M ∆3.05M
Done in 567ms
Node --> Relationship, started 2023-04-03 19:55:21.331+0000
[>:??--|>-----------------------------------|LINK--|*v:??-------------------------------------]20.5M ∆20.5M
Done in 942ms
Relationship <-- Relationship 1-1791/1791, started 2023-04-03 19:55:22.316+0000
[>---------------------|*LINK(2)=======================================|v:139.3MiB/s----------]55.8M ∆5.51M
Done in 13s 325ms
Count groups, started 2023-04-03 19:55:35.688+0000
[>|*>------------------------------------------------------------------------|COUNT:1.036GiB--]3.05M ∆3.05M
Done in 207ms
Gather, started 2023-04-03 19:55:36.026+0000
[>----|*CACHE:1.302GiB------------------------------------------------------------------------]3.05M ∆2.22M
Done in 1s 48ms
Write, started 2023-04-03 19:55:37.083+0000
[*>:??----------------------------------------------------------------------------------||v:??]2.93M ∆2.93M
Done in 266ms
Node --> Group, started 2023-04-03 19:55:37.366+0000
[>--------------------------------|*FIRST----------------------------|v:??--------------------] 158K ∆ 158K
Done in 307ms
Node counts and label index build, started 2023-04-03 19:55:37.821+0000
[*>(2)==============================|LABEL INDEX---------------------|COUNT:1.155GiB----------]21.3M ∆11.8M
Done in 922ms
Relationship counts and relationship type index build, started 2023-04-03 19:55:38.764+0000
[*>--------------------------------------------------------|REL|COUNT(2)======================]55.8M ∆28.9M
Done in 3s 5ms

IMPORT DONE in 2m 45s 772ms. 
Imported:
  21283782 nodes
  55845544 relationships
  83145318 properties
Peak memory usage: 1.336GiB
There were bad entries which were skipped and logged into /usr/src/app/neo4j/bin/import.report
Start the neo4j server in the background...
Directories in use:
  home:         /usr/src/app/neo4j
  config:       /usr/src/app/neo4j/conf
  logs:         /usr/src/app/neo4j/logs
  plugins:      /usr/src/app/neo4j/plugins
  import:       /usr/src/app/neo4j/import
  data:         /usr/src/app/neo4j/data
  certificates: /usr/src/app/neo4j/certificates
  run:          /usr/src/app/neo4j/run

Starting Neo4j.
Started neo4j (pid 361). It is available at http://localhost:7474/
There may be a short delay until the server is ready.
```

## Setting of constraints and setting to read-only
```
See /usr/src/app/neo4j/logs/neo4j.log for current status.
Waiting for server to begin fielding Cypher queries...
Cypher Query available waiting...
Cypher Query available waiting...
Cypher Query available waiting...
Creating the constraints using Cypher queries...
0 rows available after 6401 ms, consumed after another 0 ms
Deleted 571070 nodes
0 rows available after 308 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 62 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 45 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 45 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 3906 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 4804 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 10 ms, consumed after another 0 ms
Added 1 indexes
0 rows available after 6 ms, consumed after another 0 ms
Added 1 indexes
0 rows available after 11034 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 14 ms, consumed after another 0 ms
Added 1 indexes
0 rows available after 774 ms, consumed after another 0 ms
Added 1 constraints
0 rows available after 16 ms, consumed after another 0 ms
Added 1 indexes
0 rows available after 10 ms, consumed after another 0 ms
Added 1 indexes
0 rows available after 84 ms, consumed after another 0 ms
Sleeping for 2m to allow the indexes to be built before going to read_only mode...
Stopping neo4j server to go into read_only mode...
Only allow read operations from this Neo4j instance...
Restarting neo4j server in read_only mode...
Directories in use:
  home:         /usr/src/app/neo4j
  config:       /usr/src/app/neo4j/conf
  logs:         /usr/src/app/neo4j/logs
  plugins:      /usr/src/app/neo4j/plugins
  import:       /usr/src/app/neo4j/import
  data:         /usr/src/app/neo4j/data
  certificates: /usr/src/app/neo4j/certificates
  run:          /usr/src/app/neo4j/run
Starting Neo4j.
2023-04-03 19:58:37.913+0000 INFO  Starting...
2023-04-03 19:58:38.862+0000 INFO  ======== Neo4j 4.2.5 ========
2023-04-03 19:58:42.301+0000 INFO  Performing postInitialization step for component 'security-users' with version 2 and status CURRENT
2023-04-03 19:58:42.301+0000 INFO  Updating the initial password in component 'security-users'  
2023-04-03 19:58:43.019+0000 INFO  Called db.clearQueryCaches(): Query cache already empty.
2023-04-03 19:58:43.049+0000 INFO  Bolt enabled on 0.0.0.0:7687.
2023-04-03 19:58:43.492+0000 INFO  Remote interface available at http://localhost:7474/
2023-04-03 19:58:43.492+0000 INFO  Started.

```
## Result in Docker Desktop
![img_1.png](img_1.png)

## Result in browser

![img_2.png](img_2.png)

# Building a local image
It is possible to run containers from local Docker images of the UBKG. To generate from a local image, execute the following scripts in the 
docker directory:
1. build-local.sh
2. run-local.sh

# Updating the Docker Hub image
It is possible to push an update of the Docker image in DockerHub if you have the appropriate credentials to the image.