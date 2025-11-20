"""
The Neo4App class represents a connection to a UBKG neo4j instance.

The primary consumer is the add_collapsed_properties script.

ASSUMPTIONS:
1. Connect string information is in a config file named container.cfg, located in the
   application path.
2. The neo4j instance is running locally, such as in the Docker container built
   with the Shell scripts in the ubkg-neo4j repo.

"""
# To handle the common config file, which is not in INI format.
from configobj import ConfigObj

import neo4j

import time
import os
from tqdm import tqdm
import sys

class Neo4jApp:

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
        cfgfile = os.path.join(os.getcwd(),'container.cfg')
        return ConfigObj(cfgfile)

    def getnodecount(self, nodename: str):

        """
        Returns the number of nodes of specified type.
        Args:
            nodename: name of the node type.

        """
        query = f"MATCH (n:{nodename}) RETURN count(n) AS total"
        with self.driver.session() as session:
            return session.run(query).single()['total']

    def fetch_batch_and_execute(self, nodename: str, query_write: str, skip: int, limit: int):

        """
        Fetches a batch of specified nodes and executes a query against them.
        Args:
            nodename: type of node
            query_write: Cypher query string that modifies nodes
            skip, limit: batch size parameters

        Returns: number of rows processed
        """

        # Fetch the batch of nodes to process.
        query_fetch = f"""
        MATCH (n:{nodename})
        RETURN id(n) AS id
        SKIP $skip LIMIT $limit
        """
        with self.driver.session() as session:

            with session.begin_transaction() as tx:
                ids = [r["id"] for r in tx.run(query_fetch, skip=skip, limit=limit)]
                if not ids:
                    return 0
                result = tx.run(query_write, ids=ids).single()
                processed = result['processed']
                tx.commit()

        return processed