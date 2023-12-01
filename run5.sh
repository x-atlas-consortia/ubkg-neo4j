#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# neo4j Docker run script

# Please consult the README.md file in the root folder of the ubkg-neo4j repository for more information on this script.

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j Docker container script"
   echo
   echo "Syntax: ./run.sh -p password [-m database-directory] [-d docker-name] [-u username] [-n ui-port] [-b neo-bolt-port] [-t docker-tag] [-r true|false][-i]"
   echo "options (in any order)"
   echo "-p     password for the neo4j account (REQUIRED; must be at least 8 characters and include at least one alphabetic and one numeric character)"
   echo "-d     name for the Docker container (OPTIONAL; default = ubkg-neo4j)"
   echo "-u     username used to connect to the neo4j database (OPTIONAL; default = neo4j)"
   echo "-m     path to the external neo4j database (bind mount) (OPTIONAL; default = ./neo4j/data)"
   echo "-n     port to expose the neo4j browser/UI on (OPTIONAL; default = 7474)"
   echo "-b     port to expose the neo4j/bolt:// interface on (OPTIONAL; default = 7687)"
   echo "-t     the docker tag to use when running; set to local to use the local image built by docker/build-local.sh script (OPTIONAL: default = <latest released version>"
   echo "-r     run Neo4j in read-only mode; set to true or false (OPTIONAL; default = true)"
   echo "-i     for developer: build intialization container to obtain primer neo4j database (OPTIONAL: default is to build container with external bind mount"
   echo "-h     print this help"
   echo "example: './run.sh -p pwd -n 9999' creates a neo4j instance with password 'pwd' and browser port 9999 "
}
######
# Set defaults
neo4j_password=""
docker_name="ubkg-neo4j-5.11.0alpha"
neo4j_user="neo4j"
ui_port="7474"
bolt_port="7687"
docker_tag="neo-5.11.0-ALPHA1"
# read only
ro_mode="true"
# external bind mount
use_external_bind_mount="true"


# The default CSV path is ./neo4j/import, which is excluded by .gitignore.
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
# Add default path.
db_mount_dir="$base_dir"/neo4j/data

######
# Get options
while getopts ":hp:d:u:m:n:b:t:r::i" option; do
   case $option in
      i) # initialize; do not use external bind mount
        use_external_bind_mount="false";;
      h) # display Help
         Help
         exit;;
      p) # neo4j password
         neo4j_password=$OPTARG;;
      d) # docker container name
         docker_name=$OPTARG;;
      u) # user
	        echo Currently default user of neo4j cannot be changed.
	        exit 1
          neo4j_user=$OPTARG;;
      m) # db path
         db_mount_dir=${OPTARG%/};;
      n) # neo4j browser/UI port
          ui_port=$OPTARG;;
      b) # neo4j bolt interface port
        bolt_port=$OPTARG;;
      t) # docker tag
	docker_tag=$OPTARG;;
      r) # docker tag
	ro_mode=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

######
# Validate options

# Read/Write mode
if [ "$ro_mode" == "true" ]
then
  rw_mode="read-only"
elif [ "$ro_mode" == "false" ]
then
  rw_mode="read-write"
else
  echo "Error: no read/write mode specified. The -r flag must specify true or false as an argument to specify read-only mode.  Case counts."
  exit
fi   

# Docker tag for container
if [ "$docker_tag" == "local" ]
then
  docker_image_name="ubkg-neo4j-local"
else
  docker_image_name="hubmap/ubkg-neo4j:$docker_tag"
fi

# Check for password
if [ "$neo4j_password" == "" ]
then
  echo "Error: no neo4j password specified. Call this script with option -p and an argument.";
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

# Check for Docker container name
if [ "$docker_name" == "" ]
then
  echo "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify the Docker name with the -d option."
  exit 1;
fi

# Check for neo4j user name
if [ "$neo4j_user" == "" ]
then
  echo "Error: no neo4j user name. Either accept the default (neo4j) or specify the Docker name with the -u option."
  exit 1;
fi

# Check for integer browser port
if ! [[ "$ui_port" =~ ^[0-9]+$ ]]
then
  echo "Error: non-integer neo4j browser port. Either accept the default (7474) or specify an integer with the -n option."
  exit 1;
fi

if [ "$ui_port" == "" ]
then
  echo "Error: null neo4j browser port. Either accept the default (7474) or specify an integer with the -n option."
  exit 1;
fi

# Check for integer bolt port
if ! [[ "$bolt_port" =~ ^[0-9]+$ ]]
then
  echo "Error: non-integer bolt port. Either accept the default (7687) or specify an integer with the -b option."
  exit 1;
fi

if [ "$bolt_port" == "" ]
then
  echo "Error: null bolt port. Either accept the default (7687) or specify an integer with the -b option."
  exit 1;
fi

# If using an external bind mount, check to make sure external database files exist in the specified mount path.
if [ "$use_external_bind_mount" == "true" ]
then

  if [ ! -d "$db_mount_dir" ]
  then
    echo "Error: no external bind mount path '$db_mount_dir' exists. A full set of Neo4j 5.x database files must exist at '$db_mount_dir'"
    exit 1;
  fi

  # Check for existence of ontology database directory and dabase auth file
  ont_db_dir="$db_mount_dir"/databases/neo4j
  # auth_file="$db_mount_dir"/dbms/auth.ini

  if [ ! -d "$ont_db_dir" ]
  then
    echo "Error: no path '$ont_db_dir' exists. The directory containing the ontology database does not exist. Be sure to copy a UBKG database to '$db_mount_dir'"
    exit 1;
  fi

  # if [ ! -f "$auth_file" ]
  #then
  #  echo "Error: no file '$auth_file' exists. The Neo4j authorization file does not exist, make sure you've downloaded a UBKG database and copied to '$db_mount_dir'"
  #  exit 1;
  #fi
fi # $use_external_bind_mount check

echo ""
echo "**********************************************************************"
echo "A Docker container for a neo4j instance will be created using the following parameters:"
echo "  - container name: " $docker_name
echo "  - neo4j account name: $neo4j_user"
#echo "  - neo4j account password: $neo4j_password"
echo "  - neo4j browser/UI port: $ui_port"
echo "  - neo4j bolt port: $bolt_port"
if [ "$use_external_bind_mount" == "true" ]
then
  echo "  - external bind mount path: $db_mount_dir"
else
  echo "  - No external bind mount path. Run extract_primer.sh to copy primer database from container named $docker_name."
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
docker stop "$docker_name" > /dev/null 2>&1
docker rm "$docker_name" > /dev/null 2>&1

if [ "$use_external_bind_mount" == "true" ]
then
  docker run -it \
       -p "$ui_port":7474 \
       -p "$bolt_port":7687 \
       -v "$db_mount_dir":/usr/src/app/neo4j/data \
       --env NEO4J_USER="$neo4j_user" \
       --env NEO4J_PASSWORD="$neo4j_password" \
       --env UI_PORT="$ui_port" \
       --env BOLT_PORT="$bolt_port" \
       --env RW_MODE="$rw_mode" \
       --name "$docker_name" \
       "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"
else
  docker run -it \
       -p "$ui_port":7474 \
       -p "$bolt_port":7687 \
       --env NEO4J_USER="$neo4j_user" \
       --env NEO4J_PASSWORD="$neo4j_password" \
       --env UI_PORT="$ui_port" \
       --env BOLT_PORT="$bolt_port" \
       --env RW_MODE="$rw_mode" \
       --name "$docker_name" \
       "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"
fi

#grep -v commands above hide confusing messages coming from inside the container about
#how to connect to Neo4j potentially only from inside the container if the port number
#are not the defaults for the external mappings
