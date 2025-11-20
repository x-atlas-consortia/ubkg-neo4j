# coding: utf-8
"""
add_collapsed_properties.py

The UBKG native architecture represents concepts and concept-code synonymy by means of "concept
sugraphs" centered around the Concept node, as described at https://ubkg.docs.xconsortia.org/datamodel/#the-concept-subgraph.

It is possible to "collapse" a concept subgraph into properties that can be set on the Concept node.
Collapsing concept subgraphs offers an alternative route for analytical queries.

This script is run after a native UBKG database has been created. It collapses each Concept node's
subgraph into a JSON string property.

Because a UBKG instance contains millions of nodes, the script breaks collapse processing into
batches with commits, showing progress.

"""
import sys
import os
from tqdm import tqdm

# Neo4J interface class
from neo4japp import Neo4jApp

# Processing batch size
BATCH_SIZE = 100
NODENAME = 'Concept'

def getbatchquerystring() -> str:
    # Read the Cypher query string.
    fpath = os.path.join(os.getcwd(), 'python/cypher/add_collapsed_concept_subgraph_property.cypher')
    f = open(fpath, "r")
    query = f.read()
    f.close()
    return query

def main():

    # Get the connection to the UBKG, based on information in the config file.
    sys.stderr.write('Connecting to UBKG instance...\n')
    neo4j_ubkg = Neo4jApp()
    query = getbatchquerystring()

    nodecount = neo4j_ubkg.getnodecount(nodename=NODENAME)
    sys.stderr.write(f'The UBKG instance has {nodecount} Concept nodes.\n')

    pbar = tqdm(total=nodecount, unit="nodes")
    processed_total = 0

    # Iterate using SKIP/LIMIT. For large datasets prefer key-range pagination (id range)
    for skip in range(0, nodecount, BATCH_SIZE):
        processed = neo4j_ubkg.fetch_batch_and_execute(nodename=NODENAME, query_write=query, skip=skip, limit=BATCH_SIZE)
        # Update TQDM after the batch is committed.
        processed_total += processed
        pbar.update(processed)
    pbar.close()


if __name__ == "__main__":
    main()