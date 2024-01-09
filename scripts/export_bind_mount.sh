#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Export script that:
# 1. Reads a config file to obtain properties of a Docker container hosting a neo4j instance.
# 2. Extracts the complete database from the neo4j instance.

# Assumptions:
# 1. neo4j Community Edition
# 2. The container specified by the config file has an internal database--i.e., no external bind mount.

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j database export script"
   echo "Exports the database (data folder) of a neo4j instance hosted in a Docker container."
   echo
   echo "Syntax: ./export_db.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg')"
   echo "-h   print this help"
   echo "example: './export_bind_mounts.sh' exports the data and import folders of the container specified in the config file."
   echo "Review container.cfg.example for descriptions of parameters."
}

##############################
# SET DEFAULTS.
config_file="container.cfg"
container_name="ubkg-neo4j"

# Default path to external bind mount
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
# Add default path.
db_mount_dir="$base_dir"

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
# VALIDATE PARAMETERS OBTAINED FROM CONFIG FILE.
# Check for Docker container name
if [ "$container_name" == "" ]
then
  echo "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify container_name in the config file."
  exit 1;
fi

echo ""
echo "**********************************************************************"
echo "The database will be extracted from the neo4j instance in the container with the following properties:"
echo "  - container name: " $container_name

##############################
# EXPORT DATABASE TO BIND MOUNT PATH.
docker cp "$container_name":/usr/src/app/neo4j/data/ "$db_mount_dir"/data
