#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Custom health check for ubkg-back-end container.

echo docker exec -it ubkgbox-ubkg-back-end-1 /usr/src/app/neo4j/bin/cypher-shell -u "${NEO4J_USER}" -p "${NEO4J_PASSWORD}" 'match (n) return count(n);' >/dev/null 2>&1

