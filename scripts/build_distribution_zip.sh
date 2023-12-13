#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Build a Zip archive for a UBKG distribution.
#


###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG Zip distribution build script"
   echo "Builds a Zip distribution of the UBKG neo4j Docker instance from content in the current directory.."
   echo
   echo "Syntax: ./build_container.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
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


echo ""
echo "**********************************************************************"
echo "Stopping container $container_name"
# Stopping the container shuts down the neo4j server so that the data in the external bind mount is stable prior
# to copying.
# Piping with true results in success even if the container is not running.
docker stop "$container_name" || true

# A distribution consists of:
# 1. An external bind mount database.
# 2. The example config file.
# 3. The build_container script.
zip -r "$container_name.zip" data/
zip "$container_name.zip" container.cfg.example
zip "$container_name.zip" build_container.sh

echo "The UBKG distribution is available in $container_name.zip."
