# coding: utf-8
"""
create_indexes_and_constraints

Creates constraints and relationship indexes synchronously.

PROBLEM:
The UBKG requires relationship indexes on all relationships. It is possible to identify all
relationship types in UBKG via Cypher and execute CREATE INDEX commands for all of them.

Because index creation in neo4j is asynchronous, submitting a large number of CREATE INDEX commands results
in the creation of a large number of simultaneous parallel threads. For large neo4j database, the memory
required to populate a large number of databases results in an Out of Memory Error, at least for machines
with a normal amount of memory (e.g., 32 GB).

SOLUTION:
A way to avoid memory issues is to generate indexes synchronously. However, it does not appear
possible to generate indexes synchronously in neo4j via Cypher or apoc, at least in the Community Edition.

This script forces synchronous generation of constraints and indexes.

DEPENDENCIES:
1. A configuration file named container.cfg, used by all scripts in the repo, should be somewhere in
   the application path.
2. Installation of packages in requirements.txt.
3. A set of Cypher statements in a subdirectory named cypher.

"""

# To handle the common config file, which is not in INI format.
from configobj import ConfigObj
import neo4j
import time
import os
from tqdm import tqdm


# ----------------------------------
class Neo4jApp:

    # Represents a connection to a neo4j instance.
    # ASSUMPTIONS:
    # 1. Connect string information is in a config file named container.cfg, located in the
    #    application path.
    # 2. The neo4j instance is running locally, such as in the Docker container built
    #    with the Shell scripts in the repo.

    def __init__(self):

        # Read information from common config file.

        self.config = self.get_config()
        neo4j_pasword = self.config.get('neo4j_password')
        bolt_port = self.config.get('bolt_port')

        # Connect to the specified UBKG instance.
        uri = f'bolt://localhost:{bolt_port}'
        auth = ("neo4j", neo4j_pasword)

        self.driver = neo4j.GraphDatabase.driver(uri, auth=auth)

    def close(self):
        self.driver.close()

    def get_config(self) -> ConfigObj:

        # Read from the common config file, which is assumed to be somewhere in the application path.
        cfgfile = '../container.cfg'
        return ConfigObj(cfgfile)


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


def get_cuicuis(application: Neo4jApp) -> list[str]:
    """
    Obtains a list of relevant relationships between Concept nodes in the UBKG.
    Args:
        application: neo4j connection

    Returns:
        neo4j.Result object

    """

    print('Obtaining relevant CUI-CUI relationship types...')

    # Read the Cypher query string.
    fpath = os.path.join(os.path.curdir, 'cypher/get_cuicuis.cypher')
    query = read_file(file_name=fpath)

    # Execute the query.
    listresult = []
    with application.driver.session() as session:
        recds: neo4j.Result = session.run(query)
        for record in recds:
            listresult.append(record['relationshipType'])

    return listresult


def get_tuis(application: Neo4jApp) -> list[str]:
    """
    Obtains a list of relevant relationships between Concept nodes and other nodes in the UBKG.
    Args:
        application: neo4j connection

    Returns:
        neo4j.Result object

    """

    print('Obtaining relevant TUI relationship types...')

    # Read the Cypher query string.
    fpath = os.path.join(os.path.curdir, 'cypher/get_tuis.cypher')
    query = read_file(file_name=fpath)

    # Execute the query.
    listresult = []
    with application.driver.session() as session:
        recds: neo4j.Result = session.run(query)
        for record in recds:
            listresult.append(record['relationshipType'])

    return listresult


def indexes_are_populating(application: Neo4jApp) -> bool:
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


def execute_write_query(application: Neo4jApp, query: str):
    """
    Executes a single statement that writes to the database.
    Args:
        application: neo4j connection
        query: query string.

    Assumption: query is a Cypher command that writes to the database--e.g., CREATE INDEX; DELETE; etc.

    Returns: nothing

    """

    # Enforce synchronous index creation.
    while indexes_are_populating(application=application):
        # print('At least one index is still populating. Waiting 1 second...')
        time.sleep(1)

    # Transaction management is not necessary for the known use cases, so just use session.run.
    with application.driver.session() as session:
        session.run(query)

    return


def create_single_rsab_relationship_index(application: Neo4jApp, relationship_type: str):
    """
    Creates relationship indexes of type rSAB_* between two UBKG nodes of type Concept.

    Args:
        application: neo4j connection
        relationship_type: label for a relationship type.

    Returns: nothing
    """

    query = f'CREATE INDEX rSAB_{relationship_type} FOR() - [r: {relationship_type}]->() ON (r.SAB)'
    execute_write_query(application=application, query=query)

    return


def create_single_rcui_relationship_index(application: Neo4jApp, relationship_type: str):
    """
    Creates relationship indexes of type rCUI_<relationship_type> on the CUI property.

    Args:
        application: neo4j connection
        relationship_type: label for a relationship type.

    Returns: nothing
    """
    query = f'CREATE INDEX rCUI_{relationship_type} FOR() - [r: {relationship_type}]->() ON (r.CUI)'
    execute_write_query(application=application, query=query)

    return


def create_r_sab_fulltext_index(application: Neo4jApp):
    """
    Creates relationship fulltext indexes of type r_SAB on the SAB property of relationships between
    Concept nodes.

    Args:
        application: neo4j connection

    Returns: nothing
    """

    print(f'Creating r_SAB FULLTEXT index on SAB property of Concept-Concept relationships...')

    # Read the Cypher query string.
    fpath = os.path.join(os.path.curdir, 'cypher/create_rSAB_index.cypher')
    query = read_file(file_name=fpath)

    execute_write_query(application=application, query=query)

    return


def create_rsab_relationship_indexes(application: Neo4jApp):
    """
    Creates relationship indexe on the SAB property of relationships between nodes of type
    Concept--aka, "CUI-CUI" relationships.

    Args:
        application: neo4j connection

    Returns: nothing

    """

    # Execute Cypher query that returns list of relevant relationships that need indexes.
    relationships = get_cuicuis(application=application)

    # Create rSAB_* relationship indexes synchronously.
    print(f'Creating rSAB_<SAB> indexes synchronously on SAB property of Concept-Concept relationships...')
    for rel in tqdm(relationships):
        create_single_rsab_relationship_index(application=neo4j_ubkg, relationship_type=rel)

    return


def create_rcui_relationship_indexes(application: Neo4jApp):
    """
    Creates relationship indexes on the CUI property of relationships.

    Args:
        application: neo4j connection

    Returns: nothing

    """

    # Execute Cypher query that returns list of relevant relationships that need indexes.
    relationships = get_tuis(application=application)

    # Create rSAB_* relationship indexes synchronously.
    print(f'Creating rCUI_<relationship> indexes synchronously on the CUI property...')
    for rel in tqdm(relationships):
        create_single_rcui_relationship_index(application=neo4j_ubkg, relationship_type=rel)

    return


def create_constraints_and_node_indexes(application: Neo4jApp):
    """
    Creates a set of constraints and node indexes via synchronous execution.
    Args:
        application: neo4j connection

    Returns: nothing

    """

    print('Creating constraints and node indexes...')
    # Read the Cypher query string. This will be a set of Cypher statements delimited with semicolons.
    fquery = os.path.join(os.path.curdir, 'cypher/create_constraints_and_node_indexes.cypher')
    querystring = read_file(file_name=fquery)
    print('Executing the following Cypher queries synchronously:')
    print(querystring)

    # Split commands for synchronous execution.
    listcypher = querystring.split(';')

    for query in tqdm(listcypher):
        querystrip = query.strip()
        if querystrip != '':
            execute_write_query(application=application, query=querystrip)
    return


# ----------- MAIN -------------------

# Get the connection to the UBKG, based on information in the config file.
neo4j_ubkg = Neo4jApp()

# Execute Cypher queries synchronously that create constraints and node indexes.
create_constraints_and_node_indexes(application=neo4j_ubkg)

# Create rSAB_* full text relationship index on the SAB property of relationships synchronously.
create_r_sab_fulltext_index(application=neo4j_ubkg)

# Enforce synchronous index creation.
while indexes_are_populating(application=neo4j_ubkg):
    print('Waiting 10 minutes for the rSAB index to finish...')
    time.sleep(600)

# Execute Cypher queries synchronously that create rSAB_<SAB> indexes on the SAB properties of
# relationships between Concept nodes.
create_rsab_relationship_indexes(application=neo4j_ubkg)

# Execute Cypher queries synchronously that create rCUI_<relationship> indexes on the CUI property of
# relationships.
create_rcui_relationship_indexes(application=neo4j_ubkg)
