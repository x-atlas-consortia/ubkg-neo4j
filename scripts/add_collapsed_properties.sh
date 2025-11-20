#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Adds "collapsed Concept subgraph" properties to Concept nodes in an UBKG database after import.
#

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j add collapsed properties script"
   echo "Adds 'collapsed concept subgraph' properties to the Concept nodes of a UBKG database in a neo4j instance hosted in a Docker container."
   echo
   echo "Syntax: ./add_collapsed_properties.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
    echo "Review container.cfg.example for descriptions of parameters."
}
##############################
# Set defaults.
config_file="container.cfg"
container_name="ubkg-neo4j"
neo4j_user="neo4j"

# Default relative paths
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"

# Default Java max heap setting for index creation, based on recommendations for
# a machine with 32 GB of RAM working with a neo4j instance with a 27 GB database
# (Data Distillery).
#heap_indexing="3.500g"

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
echo "Adding collapsed concept subggraph properties"
echo " - Docker container: $container_name"

# Connect to the neo4j instance and import CSVs.

# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j

VENV=./venv

echo "Executing Python script..."
if [[ -d ${VENV} ]] ; then
  echo "*** Using Python venv in ${VENV}"
  source ${VENV}/bin/activate
else
  echo "*** Installing Python venv to ${VENV}"
  python3 -m venv ${VENV}
  python3 -m pip install --upgrade pip
  source ${VENV}/bin/activate
  echo "*** Installing required packages..."
  pip install -r ./python/requirements.txt
  echo "*** Done installing python venv"
fi
python3 ./python/add_collapsed_properties.py




