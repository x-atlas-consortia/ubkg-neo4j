#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Export script that:
# 1. Reads a config file to obtain properties of a Docker container hosting a neo4j instance.
# 2. Extracts the complete database from the neo4j instance.

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j database export script"
   echo "Exports the database (data folder) of a neo4j instance hosted in a Docker container.
   echo
   echo "Syntax: ./export_db.sh [-c config file]""
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container"
   echo "-h   print this help"
   echo "example: './export_bind_mounts.sh -c container.cfg' exports the data and import folders of the container specified in the config file."
}
######
# Set defaults.
config_file=""
docker_name="ubkg-neo4j"

# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
# Add default path.
db_mount_dir="$base_dir"

######
# Get options
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

###### Read parameters from config file.
if [ ! -e "$config_file" ]
then
  echo "Error: no config file '$config_file' exists."
  exit 1;
else
  source "$config_file";
fi
######
# Validate options

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

echo " "
echo "**************"
echo "Exporting database from Docker container"
#mkdir "$db_mount_dir"/data
docker cp "$container_name":/usr/src/app/neo4j/data/ "$db_mount_dir"/data
echo "Exporting import folder from Docker container"
#mkdir "$db_mount_dir"/import
docker cp "$container_name":/usr/src/app/neo4j/import/ "$import_dir"/import
