# coding: utf-8
"""
Creates relationship indexes synchronously.

Problem:
The UBKG requires relationship indexes on all relationships. It is possible to identify all
relationship types in UBKG via Cypher and execute CREATE INDEX commands for all of them.

Because index creation in neo4j is asynchronous, submitting a large number of CREATE INDEX commands results
in the creation of a large number of simultaneous parallel threads. For large neo4j database, the memory
required to populate a large number of databases results in an Out of Memory Error, at least for machines
with a normal amount of memory (e.g., 32 GB).

A way to manage the memory requirements is to generate indexes synchronously. However, it does not appear
possible to generate indexes synchronously in neo4j, at least in the Community Edition.

This script forces synchronous generation of relationship indexes.

"""

import os
# To handle the common config file, which is not in INI format.
from configobj import ConfigObj
import neo4j
import time

# ----------------------------------
class neo4j_app:

    # neo4j connection
    def __init__(self):
        # Read information from common config file.

        self.config = self.get_config()

        neo4j_pasword = self.config.get('neo4j_password')
        ui_port = self.config.get('ui_port')
        bolt_port = self.config.get('bolt_port')

        # Connect to local instance.
        URI = f'bolt://localhost:{bolt_port}'
        AUTH = ("neo4j", neo4j_pasword)

        self.driver = neo4j.GraphDatabase.driver(URI, auth=AUTH)

    def close(self):
        self.driver.close()

    def get_config(self) -> ConfigObj:
        # Read from the common config file, which is assumed to be in the application folder.
        cfgfile = 'container.cfg'

        config = ConfigObj(cfgfile)

        return config

# ----------------------------------
def read_file(file_name: str) -> str:
    """
    Reads a string from a file.
    Args:
        file_name: path to file.

    Returns: contents of file.

    """
    f = open(file_name, "r")
    query = f.read()
    f.close()
    return query

def get_cui_cuis(application: neo4j_app) -> list[str]:
    """
    Executes a read query and returns the result.
    Args:
        application: neo4j connection
        query_file: file containing a Cypher query string.

    Returns:
        neo4j.Result object

    """
    # Read the Cypher query string.
    query = read_file(file_name='get_cui_cuis.cypher')

    listResult = []
    with application.driver.session() as session:
        recds: neo4j.Result = session.run(query)
        for record in recds:
            listResult.append(record['relationshipType'])

    return listResult

def indexes_are_populating(application: neo4j_app) -> bool:
    """
    Determines whether any indexes are still populating.
    Args:
        application: neo4j connection

    Returns:
        True - at least one index is populating.

    """
    query = "SHOW INDEXES YIELD state, populationPercent WHERE state <> 'FAILED' " \
            "AND populationPercent <100 RETURN COUNT(populationPercent) AS number_populating"
    with application.driver.session() as session:
        recds: neo4j.Result = session.run(query)
        for record in recds:
            return record['number_populating'] > 0

def create_r_sab(application: neo4j_app, relationship_type: str) -> str:
    """
    Creates a relationship index on a relationship.
    Args:
        application: neo4j connection
        relationship_type: label for a relationship.

    Returns: nothing
    """

    query = f'CREATE INDEX rSAB_{relationship_type} FOR() - [r: {relationship_type}]->() ON(r.SAB)'
    with application.driver.session() as session:
        recds: neo4j.Result = session.run(query)
        query = f"SHOW INDEXES YIELD name WHERE name='rSAB_{relationship_type}' RETURN name"
        recds: neo4j.Result = session.run(query)
        for r in recds:
            return r['name']

# -----------
# Get the connection to the UBKG, based on information in the config file.
neo4j_ubkg = neo4j_app()

# Execute Cypher query that returns list of relevant relationships that need indexes.
print('Getting relevant CUI-CUI relationship types...')
relationships = get_cui_cuis(application=neo4j_ubkg)

# For each relationship in the list:
# - while the number of indexes for which populationPercent < 100
#     sleep
# - create the relationship index for the relationship
# for r in relationships:

print(f'Creating {len(relationships)} indexes...')
irel = 0
for r in relationships:
    while indexes_are_populating(application=neo4j_ubkg):
        print('At least one index is still populating. Waiting 1 second...')
        time.sleep(1)
    print(f'-- relationship {irel}: {r}')
    test = create_r_sab(application=neo4j_ubkg, relationship_type=r)
    irel = irel + 1

