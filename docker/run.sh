#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# neo4j Docker run script

# Please consult the README.md file in the root folder of the ubkg-neo4j repository for information on this script.

###########
# Help function
##########
Help()
{
   # Display Help
   echo "UBKG neo4j Docker container script"
   echo
   echo "Syntax: ./run.sh [-option1] [argument1] [-option2] [argument2]..."
   echo "options (in any order)"
   echo "p     password for the neo4j account (REQUIRED)"
   echo "d     name for the Docker container (OPTIONAL; default = ubkg-neo4j"
   echo "u     username used to connect to the neo4j database (OPTIONAL; default = neo4j)"
   echo "c     path to the directory in the local repository containing the ontology CSV files (OPTIONAL; default = current directory)"
   echo "n     port to expose the neo4j browser/UI on (OPTIONAL; default = 7474)"
   echo "b     port to expose the neo4j/bolt:// interface on (OPTIONAL; default = 7687)"
   echo "h     print this help"
   echo "example: './run.sh -p pwd -n 9999' creates a neo4j instance with password 'pwd' and browser port 9999 "
}
######
# Set defaults
neo4j_password=""
docker_name="ubkg-neo4j"
neo4j_user="neo4j"
ui_port="7474"
neo4j_port="7687"

# The default CSV path is ../neo4j/import
csv_dir="$(dirname -- "${BASH_SOURCE[0]}")" # relative
csv_dir="$(cd -- "$csv_dir" && pwd -P;)"    # absolute
csv_dir="$(dirname -- "$csv_dir")"          # parent
csv_dir+="/neo4j/import"

######
# Get the options
while getopts ":hp:u:c:n:b:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p) #password
         neo4j_password=$OPTARG;;
      u) # user
        neo4j_user=$OPTARG;;
      c) # csv path
        csv_dir=$OPTARG;;
      n) # neo4j browser/UI port
        ui_port=$OPTARG;;
      b) # neo4j bolt interface port
        neo4j_port=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

######
# Main program

# Check for password
if [ "$neo4j_password" == "" ]
then
  echo "Error: no neo4j password specified. Call this script with option -p and an argument.";
  exit 1;
fi

# Check for Docker container name (in case it was cleared via parameter)
if [ "$docker_name" == ""]
then
  echo "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify the Docker name with the -d option."
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
echo "***********"
echo "All 12 required ontology CSV files were found in directory '$csv_dir'."
echo ""
echo "A Docker container for a neo4j instance will be created using the following parameters:"
echo "  - neo4j account name: $neo4j_user"
echo "  - neo4j account password: $neo4j_password"
echo "  - CSV directory: $csv_dir"
echo "  - neo4j browser/UI port: $ui_port"
echo "  - neo4j bolt port: $neo4j_port"