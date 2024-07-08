#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Shuts down the UBKG neo4j instance, waiting until all processes are complete.
#


###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j shutdown script"
   echo "Shuts down an UBKG database in a neo4j instance hosted in a Docker container."
   echo
   echo "Syntax: ./shutdown_neo4j.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
   echo "example: './shudown_neo4j.sh' shuts down the container/instance specified in the config file."
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


echo ""
echo "**********************************************************************"
echo "Shutting down neo4j server"
echo " - Docker container: $container_name"

# Neo4j binary directory.
NEO4J=/usr/src/app/neo4j/bin

# Stop the neo4j database
docker exec "$container_name" \
bash -c "./neo4j stop"

echo "Exit Code:"
docker inspect "$container_name" --format={{.State.ExitCode}}



