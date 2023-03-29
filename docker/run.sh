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
   echo "u     username used to connect to the neo4j database (OPTIONAL; default=neo4j)"
   echo "c     path to the directory in the local repository containing the ontology CSV files (OPTIONAL; default=current directory)"
   echo "n     port to expose the neo4j browser/UI on (OPTIONAL; default=7474)"
   echo "b     port to expose the neo4j/bolt:// interface on (OPTIONAL; default=7687)"
   echo "h     print this help"
   echo "example: './run.sh -p pwd -n 9999' creates a neo4j instance with password 'pwd' and browser port 9999 "
}
######
# Set defaults
neo4j_password=""
neo4j_user="neo4j"
csv_dir=""
ui_port="7474"
neo4j_port="7687"

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

# Check for existence of CSV directory.
if [ ! -d $csv_dir ]
then
  echo "Error: no path $csv_dir exists. Call this script with option c and an argument that specifies the path to the directory that contains the ontology CSV files."
fi

echo "password: $neo4j_password"
echo "user: $neo4j_user"
echo "csv_dir: $csv_dir"
echo "ui_port: $ui_port"
echo "bolt port: $neo4j_port"