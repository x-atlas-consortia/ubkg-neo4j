#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Build a UBKGBox multi-container application.


###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKGBox build script"
   echo "Builds a Docker Compose multi-container application named ubkgbox."
   echo
   echo "Syntax: ./build_ubkgbox.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
   echo "Review container.cfg.example for descriptions of parameters."
}
##############################
# Set defaults.
config_file="container.cfg"

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

# neo4j password
if [[ "$neo4j_password" == "" ]]
then
  echo "Error: no neo4j_password specified in config file."
  exit 1;
fi

# Export neo4j username and password to pass to the start.sh script of the Dockerfile in the
# ubkg-back-end container.
export NEO4J_USER="neo4j"
export NEO4J_PASSWORD="$neo4j_password"

# Call Docker compose
docker compose up
