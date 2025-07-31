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

# JAS August 2024
# Check status of index population.
function test_index_population {
  # The query will return a string in format 'p x', where x is the number of indexes that are still populating.
  # A return of "0" indicates that all indexes have been built.
  local test=$(echo 'SHOW INDEXES YIELD state, populationPercent WHERE populationPercent <100 RETURN COUNT(populationPercent) AS p;' | ${NEO4J}/bin/cypher-shell -u ${NEO4J_USER} -p ${NEO4J_PASSWORD})
  # Trim the leading "p ".
  test=$(echo $test | tr -d 'p ')
  echo $test
}

# echo "Starting the neo4j server; resetting the password; then restarting."
# echo "Please wait, this may take a minute or two..."
echo 'Starting the neo4j server...'

echo 'Disabling authentication...'
# Disable authentication of requests to neo4j server via configuration.
cp $NEO4J/conf/neo4j.conf $NEO4J/conf/neo4j.conf.secure
cp $NEO4J/conf/neo4j.conf.noauth $NEO4J/conf/neo4j.conf

$NEO4J/bin/neo4j start > /dev/null 2>&1
until test_cypher_query ; do
    echo 'Waiting for server to start...'
    sleep 5
done

echo 'Counting the number of indexes in the neo4j database...'
# JAS Aug 2024 - Wait until all indexes have been built before moving on to other tasks, such as setting the server to read-only.
indexcount=$(echo 'SHOW INDEXES YIELD state, populationPercent RETURN COUNT(populationPercent) AS p;' | ${NEO4J}/bin/cypher-shell -u ${NEO4J_USER} -p ${NEO4J_PASSWORD})
# Trim the leading "p " from the query return.
indexcount=$(echo $indexcount | tr -d 'p ')
echo 'The neo4j database contains' $indexcount 'indexes, some of which may need to be rebuilt.'

echo 'Verifying that all indexes have been populated...'
# Initialize the count of indexes that are still populating.
indexpopulating=$(test_index_population)
# The return from test_index_population is interpreted as an integer instead of a string. ¯\_(ツ)_/¯
until [[ indexpopulating -eq 0 ]]; do
  echo $indexpopulating' indexes still populating...'
  sleep 5
  indexpopulating=$(test_index_population)
done
echo "All indexes populated."

echo 'Setting the neo4j user password...'
echo "ALTER USER $NEO4J_USER SET PASSWORD '$NEO4J_PASSWORD' SET PASSWORD CHANGE NOT REQUIRED" | $NEO4J/bin/cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" > /dev/null 2>&1
sleep 5
echo 'Stopping the neo4j server...'
if [[ ! `$NEO4J/bin/neo4j stop` ]]; then
  while [[ `$NEO4J/bin/neo4j status` ]]; do
    echo "Waiting for neo4j to stop..."
    sleep 2
  done;
fi

echo 'Re-enabling authentication in neo4j...'
# Re-enable authentication.
cp $NEO4J/conf/neo4j.conf.secure $NEO4J/conf/neo4j.conf

# Set read-write mode. The default is read-write.
if [ "$RW_MODE" == "read-only" ]
then
  echo "Setting the neo4j instance to be read-only."
  echo "server.databases.default_to_read_only=true" >> $NEO4J/conf/neo4j.conf
fi


RED='\033[0;31m' # text red color
NC='\033[0m' # No Color
echo -e "${RED}***Restarting neo4j server..."
#show the user the local ports where Neo4j can be accessed
#echo -e "***The Neo4j web desktop UI will be available at http://localhost:$UI_PORT"
#echo -e "***The neo4j/bolt interface will be available at neo4j://localhost:$BOLT_PORT and bolt://localhost:$BOLT_PORT"
echo -e "***"
echo -e "***Just a minute or so more..."
echo -e "***Wait for the \"Started Server\" message ${NC}"
# Docker requires your command to keep running in the foreground, so start with the console option. Otherwise, it thinks that your applications stops and shuts down the container.
$NEO4J/bin/neo4j console | grep -v "org\.eclipse\.jetty" | grep -v "Directories in use" | grep -v "usr/src/app/neo4j"
