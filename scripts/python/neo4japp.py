"""
The Neo4App class represents a connection to a UBKG neo4j instance.

The primary consumer is the add_collapsed_properties script.

ASSUMPTIONS:
1. Connect string information is in a config file named container.cfg, located in the
   application path.
2. The neo4j instance is running locally, such as in the Docker container built
   with the Shell scripts in the ubkg-neo4j repo.

"""

import os
import sys
from typing import List, Optional

# To handle the common config file, which is not in INI format.
from configobj import ConfigObj
import neo4j
from tqdm import tqdm


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

    def _fetch_all_ids_ordered(self, nodename: str) -> List[int]:
        """
        Fetch all node ids for nodename, ordered by id so batching is deterministic.
        Args:
             nodename: type of node to fetch.
        """
        query_fetch_all = f"""
        MATCH (n:{nodename})
        RETURN id(n) AS id
        ORDER BY id(n)
        """
        with self.driver.session() as session:
            return [record["id"] for record in session.run(query_fetch_all)]

    def _execute_write_batch(self, query_write: str, ids: List[int]) -> int:
        """
        Execute the provided write query against the given list of ids inside a
        single write transaction and commit it before returning.

        Expects the Cypher to accept parameter `ids` and to return a single row
        with a `processed` integer (e.g. RETURN COUNT(n) AS processed).

        Returns the integer processed count (0 if none).
        """

        if not ids:
            return 0

        # Use a write transaction so the driver can handle retries on transient errors.
        with self.driver.session() as session:
            def _tx_fn(tx, q, ids_param):
                rec = tx.run(q, ids=ids_param).single()
                #tx.commit()
                if not rec:
                    return 0
                # ensure we return an int
                try:
                    return int(rec.get("processed", 0))
                except Exception:
                    return 0

            return session.write_transaction(_tx_fn, query_write, ids)

    def process_nodes_in_order(
            self,
            nodename: str,
            query_write: str,
            batch_size: int,
    ) -> int:
        """
        Process all nodes of type `nodename` in deterministic ordered batches.

        - Fetches all ids (ORDER BY id) once to make pagination stable even if
          nodes change while processing.
        - Splits ids into batches, executes the write per-batch in its own
          committed transaction, and updates tqdm after each commit.

        Returns the total processed count as reported by the write query sum.
        Note: the tqdm progress is advanced by the number of ids attempted in
        each batch (len(batch_ids)). That ensures the bar reaches the full
        total (nodecount). .
        """

        sys.stderr.write('Processing...\n')
        sys.stderr.write('Fetching nodes...\n')
        all_ids = self._fetch_all_ids_ordered(nodename)
        total = len(all_ids)

        sys.stderr.write(f'{total} {nodename} nodes\n')

        # Set up the progress bar.
        pbar = tqdm(total=total, desc=f"Processing {nodename} nodes", unit="nodes", leave=True)

        processed_total = 0

        for i in range(0, total, batch_size):
            batch_ids = all_ids[i: i + batch_size]
            if not batch_ids:
                continue

            processed = self._execute_write_batch(query_write, batch_ids)
            processed_total += processed

            # Update tqdm defensively. Use the number of ids we attempted in the
            # batch so the bar always reaches `total`. If you'd prefer to update
            # by the DB-reported processed count instead, replace len(batch_ids)
            # with processed.
            remaining = max(0, pbar.total - pbar.n)
            to_update = min(len(batch_ids), remaining)
            if to_update:
                pbar.update(to_update)

        pbar.close()

        return processed_total
