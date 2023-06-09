#!/bin/bash
echo " "
echo "*****************************"
echo "UBKG ontology neo4j start script"

# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j

# Internal docker directory where ontology CSVs are mounted
IMPORT=/usr/src/app/neo4j/import

# Set JAVA_HOME
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

# Get the neo4j username, password, UI port and bolt port from system environment variables.
# The UI and bolt ports are only needed to echo a message to the user
NEO4J_USER=${NEO4J_USER}
NEO4J_PASSWORD=${NEO4J_PASSWORD}
UI_PORT=${UI_PORT}
BOLT_PORT=${BOLT_PORT}

echo "NEO4J_USER: $NEO4J_USER"

# Run a simple query which (if it succeeds) tells us that the Neo4j is running...
function test_cypher_query {
    echo 'match (n) return count(n);' | ${NEO4J}/bin/cypher-shell -u "${NEO4J_USER}" -p "${NEO4J_PASSWORD}" >/dev/null 2>&1
}

# Set the initial password of the initial admin user ('neo4j')
# And remove the requirement to change password on first login
# Must be performed before starting up the database for the first time
echo "Setting the neo4j password as the value of NEO4J_PASSWORD environment variable: $NEO4J_PASSWORD"
$NEO4J/bin/neo4j-admin set-initial-password $NEO4J_PASSWORD

echo "Importing database from CSV files"
$NEO4J/bin/neo4j-admin import --verbose --database=ontology --nodes=Semantic=$IMPORT/TUIs.csv --nodes=Concept=$IMPORT/CUIs.csv --nodes=Code=$IMPORT/CODEs.csv --nodes=Term=$IMPORT/SUIs.csv --nodes=Definition=$IMPORT/DEFs.csv --relationships=ISA_STY=$IMPORT/TUIrel.csv --relationships=STY=$IMPORT/CUI-TUIs.csv --relationships=$IMPORT/CUI-CUIs.csv --relationships=CODE=$IMPORT/CUI-CODEs.csv --relationships=$IMPORT/CODE-SUIs.csv --relationships=PREF_TERM=$IMPORT/CUI-SUIs.csv --relationships=DEF=$IMPORT/DEFrel.csv --skip-bad-relationships --skip-duplicate-nodes

echo "Start the neo4j server in the background..."
$NEO4J/bin/neo4j start

# Spin here till the neo4j cypher-shell successfully responds...
echo "Waiting for server to begin fielding Cypher queries..."
until test_cypher_query ; do
    echo 'Cypher Query available waiting...'
    sleep 1
done

echo "Creating the constraints using Cypher queries..."
# https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/
$NEO4J/bin/cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" --format verbose --fail-at-end --debug -f "/usr/src/app/set_constraints.cypher"

SLEEP_TIME=2m
echo "Sleeping for $SLEEP_TIME to allow the indexes to be built before going to read_only mode..."
sleep $SLEEP_TIME

echo "Stopping neo4j server to go into read_only mode..."
# https://neo4j.com/developer/kb/how-to-properly-shutdown-a-neo4j-database/
if [[ ! `$NEO4J/bin/neo4j stop` ]]; then
  while [[ `$NEO4J/bin/neo4j status` ]]; do
    echo "Waiting for Neo4j to stop..."
    sleep 1
  done;
fi

echo "Only allow read operations from this Neo4j instance..."
# https://neo4j.com/docs/operations-manual/current/configuration/neo4j-conf/#neo4j-conf
echo "dbms.read_only=true" >> $NEO4J/conf/neo4j.conf

RED='\033[0;31m' # text red color
NC='\033[0m' # No Color
echo -e "${RED}***Restarting neo4j server in read_only mode..."
#show the user the local ports where Neo4j can be accessed
echo -e "***The Neo4j web desktop UI will be available at http://localhost:$UI_PORT"
echo -e "***The neo4j/bolt interface will be available at neo4j://localhost:$BOLT_PORT and bolt://localhost:$BOLT_PORT ${NC}"

# Docker requires your command to keep running in the foreground, so start with the console option. Otherwise, it thinks that your applications stops and shuts down the container.
$NEO4J/bin/neo4j console
