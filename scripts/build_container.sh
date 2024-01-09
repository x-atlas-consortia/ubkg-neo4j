#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Build Container script that:
# 1. Reads a configuration file.
# 2. Builds a Docker container hosting a neo4j server.

# The script builds two types of container:
# 1. Without a bind mount. This allows for the export of an empty neo4j database appropriate to the version of neo4j.
#    This database will be a "primer" for a later import of UBKG data.
# 2. With bind mounts for neo4j data and import, pointing to directories in the application directory.

# Assumptions:
# neo4j Community Edition

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j Docker container build script"
   echo
   echo "Syntax: ./build_container.sh mode -c container.cfg"
   echo "mode (REQUIRED: default=external) relationship of neo4j database files to the neo4j server:"
   echo "     internal - databases are internal (in the Docker container)"
   echo "     external - databases are external (in a bind mount)"
   echo "-c   path to config file containing parameters for building the container (REQUIRED: default=container.cfg)"
   echo "Review container.cfg.example for descriptions of parameters."
}
##############################
# SET DEFAULTS.

# Name of the configuration file.
config_file="container.cfg"
# Name of the Docker container.
container_name="ubkg-neo4j"
# Tag for the docker container.
docker_tag="neo-5.11.0-ALPHA2"

neo4j_user="neo4j"
neo4j_password=""
ui_port="7474"
bolt_port="7687"
read_mode="read-only"
db_mode="external"

# Default paths for external bind mounts.
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
db_mount_dir="$base_dir"/data
import_dir="$base_dir"/import

##############################
# VALIDATE ARGUMENT
if [ "$1" == "h" ]
then
  Help
  exit;
fi

db_mode=$1
if [ "$1" == "" ]
then
  db_mode="external"
fi

if ! ([[ "$db_mode" == "internal" ]] || [[ "$db_mode" == "external" ]])
then
  echo "Error: invalid value for database mode. Options are 'internal' and 'external'."
  exit 1;
fi


##############################
# VALIDATE OPTIONS
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

# Read/Write mode
if [ "$read_mode" == "" ]
then
  echo "Error: no value for 'read_mode' specified in $config_file. Either accept the default (read-only) or specify a value."
  echo "Options are 'read-write' and 'read-only'."
  exit 1;
fi

if ! ([[ "$read_mode" == "read-only" ]] || [[ "$read_mode" == "read-write" ]])
then
  echo "Error: invalid value for 'read_mode'. Options are 'read-write' and 'read-only'."
  exit 1;
fi

# Docker image name for container, based on tag
if [ "$docker_tag" == "local" ]
then
  docker_image_name="ubkg-neo4j-local"
else
  docker_image_name="hubmap/ubkg-neo4j:$docker_tag"
fi

# neo4j password
if [ "$neo4j_password" == "" ]
then
  echo "Error: no neo4j_password specified in config file."
  exit 1;
fi

# Check that the password contains at least one alphabetic and one numeric character
# and that it is a minimum of 8 characters long
if ! [[ ${#neo4j_password} -ge 8 ]]
then
    echo "Error: password must be a minumum of 8 characters long."
    exit 1;
fi
if ! [[ "$neo4j_password" =~ [A-Za-z] ]]
then
    echo "Error: password must contain at least one alphabetic character."
    exit 1;
fi
if ! [[ "$neo4j_password" =~ [0-9] ]]
then
    echo "Error: password must contain at least one numeric character."
    exit 1;
fi

# Docker container name
if [ "$container_name" == "" ]
then
  echo "Error: no value for container_name. Either accept the default (ubkg-neo4j) or specify a value in the config file."
  exit 1;
fi

# neo4j user name
if [ "$neo4j_user" == "" ]
then
  echo "Error: no value for neo4j_user. Either accept the default (neo4j) or specify a value in the config file."
  exit 1;
fi

# Integer browser port
if ! [[ "$ui_port" =~ ^[0-9]+$ ]]
then
  echo "Error: non-integer neo4j browser port. Either accept the default (7474) or specify an integer for ui_port in the config file."
  exit 1;
fi

if [ "$ui_port" == "" ]
then
  echo "Error: null neo4j browser port. Either accept the default (7474) or specify an integer for ui_port in the config file."
  exit 1;
fi

# Integer bolt port
if ! [[ "$bolt_port" =~ ^[0-9]+$ ]]
then
  echo "Error: non-integer bolt port. Either accept the default (7687) or specify an integer for bolt_port in the config file."
  exit 1;
fi
if [ "$bolt_port" == "" ]
then
  echo "Error: null bolt port. Either accept the default (7687) or specify an integer for bolt_port in the config file."
  exit 1;
fi


# If using an external bind mount, check to make sure that external database files exist in the specified mount path.
if [ "$db_mode" == "external" ]
then

  echo "Checking for external bind mount volume..."
  if [ ! -d "$db_mount_dir" ]
  then
    echo "Error: no external bind mount path '$db_mount_dir' exists. A full set of Neo4j 5.x database files must exist at '$db_mount_dir'"
    exit 1;
  fi

  # Check for existence of ontology database directory and database auth file
  ont_db_dir="$db_mount_dir"/databases/neo4j

  # auth_file="$db_mount_dir"/dbms/auth.ini

  if [ ! -d "$ont_db_dir" ]
  then
    echo "Error: no path '$ont_db_dir' exists."
    echo "Either copy a pre-generated UBKG database to '$db_mount_dir' or generate a new database."
    exit 1;
  fi

  # if [ ! -f "$auth_file" ]
  #then
  #  echo "Error: no file '$auth_file' exists. The Neo4j authorization file does not exist, make sure you've downloaded a UBKG database and copied to '$db_mount_dir'"
  #  exit 1;
  #fi
fi # $use_external_bind_mount check

##############################
# BUILD CONTAINER.

echo ""
echo "**********************************************************************"
echo "A Docker container for a neo4j instance will be created using the following parameters:"
echo "  - container name: " $container_name
echo "  - neo4j account name: $neo4j_user"
echo "  - neo4j browser/UI port: $ui_port"
echo "  - neo4j bolt port: $bolt_port"
echo "  - read/write mode: $read_mode"

if [ "$db_mode" == "internal" ]
then
  echo "  - internal database (inside container)"
else
  echo "  - external database at bind mount path: $db_mount_dir"
fi

# Run Docker container, providing:
# - container name
# - Account information as environment variables
# - browser and bolt ports
# - absolute path to the directory for the external bind mount
# - neo4j image from Dockerhub
# set up shell
echo " "
echo "**************"
echo "Starting Docker container"

#if a docker container of the same name exists or is running stop and/or delete it
docker stop "$container_name" > /dev/null 2>&1
docker rm "$container_name" > /dev/null 2>&1


# Conditional instantiation.
if [ "$db_mode" == "external" ]
then
  # Create container with external bind mounts for data, import, and logs.
  docker run -it \
       -p "$ui_port":7474 \
       -p "$bolt_port":7687 \
       -v "$db_mount_dir":/usr/src/app/neo4j/data \
       -v "$import_dir":/usr/src/app/neo4j/import \
       -v "$base_dir/logs":/usr/src/app/neo4j/logs \
       --env NEO4J_USER="$neo4j_user" \
       --env NEO4J_PASSWORD="$neo4j_password" \
       --env UI_PORT="$ui_port" \
       --env BOLT_PORT="$bolt_port" \
       --env RW_MODE="$read_mode" \
       --name "$container_name" \
       "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"
else
  # Create initialization container without an external bind mount. The neo4j database inside the container
  # will be used as a primer database for the import of CSV files.
  docker run -it \
       -p "$ui_port":7474 \
       -p "$bolt_port":7687 \
       --env NEO4J_USER="$neo4j_user" \
       --env NEO4J_PASSWORD="$neo4j_password" \
       --env UI_PORT="$ui_port" \
       --env BOLT_PORT="$bolt_port" \
       --env RW_MODE="$read_mode" \
       --name "$container_name" \
       "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"
fi

#grep -v commands above hide confusing messages coming from inside the container about
#how to connect to Neo4j potentially only from inside the container if the port number
#are not the defaults for the external mappings
