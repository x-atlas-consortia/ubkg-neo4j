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
   echo "Syntax: ./run.sh [-option1] [argument1] [-option2] [argument2]..."
   echo "options (in any order)"
   echo "-p     password for the neo4j account (REQUIRED)"
   echo "-d     name for the Docker container (OPTIONAL; default = ubkg-neo4j)"
   echo "-u     username used to connect to the neo4j database (OPTIONAL; default = neo4j)"
   echo "-c     path to the directory in the local repository containing the ontology CSV files (OPTIONAL; default = ./neo4j/import)"
   echo "-n     port to expose the neo4j browser/UI on (OPTIONAL; default = 7474)"
   echo "-b     port to expose the neo4j/bolt:// interface on (OPTIONAL; default = 7687)"
   echo "-t     the docker tag to use when running, if set to local the local image built by docker/build-local.sh script is used (OPTIONAL: default = <latest released version>"
   echo "h     print this help"
   echo "example: './run.sh -p pwd -n 9999' creates a neo4j instance with password 'pwd' and browser port 9999 "
}
######
# Set defaults
neo4j_password=""
docker_name="ubkg-neo4j"
neo4j_user="neo4j"
ui_port="7474"
bolt_port="7687"
docker_tag="1.0.1"

# The default CSV path is ./neo4j/import, which is excluded by .gitignore.
# Get relative path to current directory.
csv_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
csv_dir="$(cd -- "$csv_dir" && pwd -P;)"
# Add default path.
csv_dir+="/neo4j/import"

######
# Get options
while getopts ":hp:d:u:c:n:b:t:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p) # neo4j password
         neo4j_password=$OPTARG;;
      d) # docker container name
        docker_name=$OPTARG;;
      u) # user
        neo4j_user=$OPTARG;;
      c) # csv path
        csv_dir=$OPTARG;;
      n) # neo4j browser/UI port
        ui_port=$OPTARG;;
      b) # neo4j bolt interface port
        bolt_port=$OPTARG;;
      t) # docker tag
	docker_tag=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

if [ "$docker_tag" == "local" ]
then
  docker_image_name="ubkg-neo4j-local"
else
  docker_image_name="hubmap/ubkg-neo4j:$docker_tag"
fi

######
# Validate options

# Check for password
if [ "$neo4j_password" == "" ]
then
  echo "Error: no neo4j password specified. Call this script with option -p and an argument.";
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

# Check for existence of CSV directory.
if [ ! -d "$csv_dir" ]
then
  echo "Error: no path '$csv_dir' exists. Either accept the default (/neo4j/import) or specify the the directory that contains the ontology CSV files with the -c option."
  exit 1;
fi

# Check for CSV files in CSV directory.
csvlist=("CODE-SUIs" "CODEs" "CUI-CODEs" "CUI-CUIs" "CUI-SUIs" "CUI-TUIs" "CUIs" "DEFrel" "DEFs" "SUIs" "TUIrel" "TUIs")
for str in "${csvlist[@]}"; do
  testcsv=$csv_dir$"/"$str$".csv"
  if [ ! -e "$testcsv" ]
  then
    echo "Error: No file named $str.csv in directory '$csv_dir'."
    exit 1;
  fi
done
echo ""
echo "**********************************************************************"
echo "All 12 required ontology CSV files were found in directory '$csv_dir'."
echo ""
echo "A Docker container for a neo4j instance will be created using the following parameters:"
echo "  - container name: " $docker_name
echo "  - neo4j account name: $neo4j_user"
echo "  - neo4j account password: $neo4j_password"
echo "  - CSV directory for ontology CSV files: $csv_dir"
echo "  - neo4j browser/UI port: $ui_port"
echo "  - neo4j bolt port: $bolt_port"

# Run Docker container, providing:
# - container name
# - Account information as environment variables
# - browser and bolt ports
# - absolute path to the directory that contains the ontology CSVs. (This will be a bind mount.)
# - neo4j image from Dockerhub
# set up shell
echo " "
echo "**************"
echo "Starting Docker container"

#if a docker container of the same name exists or is running stop and/or delete it
docker stop "$docker_name" > /dev/null 2>&1
docker rm "$docker_name" > /dev/null 2>&1

docker run -it \
       -p "$ui_port":7474 \
       -p "$bolt_port":7687 \
       -v "$csv_dir":/usr/src/app/neo4j/import \
       --env NEO4J_USER="$neo4j_user" \
       --env NEO4J_PASSWORD="$neo4j_password" \
       --env UI_PORT="$ui_port" \
       --env BOLT_PORT="$bolt_port" \
       --name "$docker_name" \
       "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"

#grep -v commands above hide confusing messages coming from inside the container about
#how to connect to Neo4j potentially only from inside the container if the port number
#are not the defaults for the external mappings
