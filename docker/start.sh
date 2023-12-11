#!/bin/bash
echo " "
echo "*****************************"
echo "UBKG ontology neo4j start script"

# Reconfigures the default settings from the Docker image pulled from Docker Hub,
# based on parameters in the call that builds the Docker container.

# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j

# Set JAVA_HOME
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

# Get the neo4j username, password, ports, and database name system environment variables provided by the
# container build script.

# The UI and bolt ports are only needed to echo a message to the user.
NEO4J_USER=${NEO4J_USER}
#NEO4J_PASSWORD=${NEO4J_PASSWORD}
UI_PORT=${UI_PORT}
BOLT_PORT=${BOLT_PORT}
RW_MODE=${RW_MODE}

echo "NEO4J_USER: $NEO4J_USER"

# Run a simple query which (if it succeeds) tells us that the Neo4j is running...
function test_cypher_query {
    echo 'match (n) return count(n);' | ${NEO4J}/bin/cypher-shell -u "${NEO4J_USER}" -p "${NEO4J_PASSWORD}" >/dev/null 2>&1
}

echo "Starting the neo4j server; resetting the password; then restarting."
echo "Please wait, this may take a minute or two..."

# Disable authentication of requests to neo4j server via configuration.
cp $NEO4J/conf/neo4j.conf $NEO4J/conf/neo4j.conf.secure
cp $NEO4J/conf/neo4j.conf.noauth $NEO4J/conf/neo4j.conf

$NEO4J/bin/neo4j start > /dev/null 2>&1
until test_cypher_query ; do
    echo 'Waiting for server to start...'
    sleep 5
done

# JAS added SET PASSWORD CHANGE NOT REQUIRED.
echo "ALTER USER $NEO4J_USER SET PASSWORD '$NEO4J_PASSWORD' SET PASSWORD CHANGE NOT REQUIRED" | $NEO4J/bin/cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" > /dev/null 2>&1
sleep 5
if [[ ! `$NEO4J/bin/neo4j stop` ]]; then
  while [[ `$NEO4J/bin/neo4j status` ]]; do
    echo "Waiting for Neo4j to stop..."
    sleep 2
  done;
fi

# Re-enable authentication.
cp $NEO4J/conf/neo4j.conf.secure $NEO4J/conf/neo4j.conf

## Spin here till the neo4j cypher-shell successfully responds...
#echo "Waiting for server to begin fielding Cypher queries..."
#until test_cypher_query ; do
 #   echo 'Cypher Query available waiting...'
 #  sleep 1
#done

#echo "Creating the constraints using Cypher queries..."
## https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/
#$NEO4J/bin/cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" --format verbose --fail-at-end --debug -f "/usr/src/app/set_constraints.cypher"
#
#SLEEP_TIME=2m
#echo "Sleeping for $SLEEP_TIME to allow the indexes to be built..."
#sleep $SLEEP_TIME


#echo "Stopping neo4j server to go into read_only mode..."
## https://neo4j.com/developer/kb/how-to-properly-shutdown-a-neo4j-database/
#if [[ ! `$NEO4J/bin/neo4j stop` ]]; then
#  while [[ `$NEO4J/bin/neo4j status` ]]; do
#    echo "Waiting for Neo4j to stop..."
#    sleep 1
#  done;
#fi

#echo "Only allow read operations from this Neo4j instance..."
# https://neo4j.com/docs/operations-manual/current/configuration/neo4j-conf/#neo4j-conf

# Set read-write mode. The default is false.
if [ "$RW_MODE" == "read-only" ]
then
  echo "Setting the neo4j instance to be read-only."
  echo "server.databases.default_to_read_only=true" >> $NEO4J/conf/neo4j.conf
fi


RED='\033[0;31m' # text red color
NC='\033[0m' # No Color
echo -e "${RED}***Restarting neo4j server mode..."
#show the user the local ports where Neo4j can be accessed
echo -e "***The Neo4j web desktop UI will be available at http://localhost:$UI_PORT"
echo -e "***The neo4j/bolt interface will be available at neo4j://localhost:$BOLT_PORT and bolt://localhost:$BOLT_PORT"
echo -e "***"
echo -e "***Just a minute or so more..."
echo -e "***Wait for the \"Started Server\" message ${NC}"
# Docker requires your command to keep running in the foreground, so start with the console option. Otherwise, it thinks that your applications stops and shuts down the container.
$NEO4J/bin/neo4j console | grep -v "org\.eclipse\.jetty" | grep -v "Directories in use" | grep -v "usr/src/app/neo4j"
