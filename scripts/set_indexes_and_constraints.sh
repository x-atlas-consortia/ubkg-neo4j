#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Set indexes and constraints on a UBKG database after import.
#


###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j index and constraint script"
   echo "Applies a set of indexes and constraints to a new ontology database in a neo4j instance hosted in a Docker container."
   echo
   echo "Syntax: ./set_indexes_and_constraints.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
   echo "example: './set_indexes_and_constraints.sh' sets constraints on the container/instance specified in the config file."
   echo "Review container.cfg.example for descriptions of parameters."
}
##############################
# Set defaults.
config_file="container.cfg"
container_name="ubkg-neo4j-5.11.0alpha"

# Default relative paths
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"

##############################
# PROCESS OPTIONS
while getopts ":hc:" option; do
  case $option in
    h) # display Help
      Help
      exit;;
    c) # config file
      config_file=$OPTARG;;
    \?) # Invalid option
      echo "Error: Invalid option"
      exit;;
  esac
done

##############################
# READ PARAMETERS FROM CONFIG FILE.

if [ "$config_file" == "" ]
then
  echo "Error: No configuration file specified. This script obtains parameters from a configuration file."
  echo "Either accept the default (container.cfg) or specify a file name using the -c flag."
  exit;
fi
if [ ! -e "$config_file" ]
then
  echo "Error: no config file '$config_file' exists."
  exit 1;
else
  source "$config_file";
fi

##############################
# VALIDATE PARAMETERS FROM CONFIG FILE.

# Check for Docker container name.
if [ "$container_name" == "" ]
then
  echo "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify container_name in the config file."
  exit 1;
fi

# neo4j user name
if [ "$neo4j_user" == "" ]
then
  echo "Error: no value for neo4j_user. Either accept the default (neo4j) or specify a value in the config file."
  exit 1;
fi

# neo4j password
if [ "$neo4j_password" == "" ]
then
  echo "Error: no neo4j_password specified in config file."
  exit 1;
fi


echo ""
echo "**********************************************************************"
echo "Setting constraints and indexes"
echo " - Docker container: $container_name."

# Connect to the neo4j instance and import CSVs.

# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j

docker exec "$container_name" \
"$NEO4J"/bin/cypher-shell \
-u "$neo4j_user" -p "$neo4j_password" \
--format verbose \
--fail-at-end \
-f "/usr/src/app/indexes_constraints.cypher"


echo "Setting of constraints and indexes complete."
