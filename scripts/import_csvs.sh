#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# CSV Import script:
# 1. Reads a configuration file of properties of a Docker container hosting an instance of neo4j.
# 2. Connects to the Docker container.
# 3. Imports a set of CSVs into a new database named ontology.
# 4. Stops the neo4j instance.
# 5. Resets the default database to point to the ontology database.
# 6. Restarts the neo4j instance.

###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j CSV import script"
   echo "Imports a set of CSVs into a new ontology database in a neo4j instance hosted in a Docker container.
   echo
   echo "Syntax: ./export_db.sh [-c config file]""
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container"
   echo "-h   print this help"
   echo "example: './import_csvs.sh -c container.cfg' exports the data folder of the container specified in the config file."
}
######
# Set defaults.
config_file=""
docker_name="ubkg-neo4j"

# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
# Add default path to CSV.
csv_dir="$base_dir/CSV"
# Default external bind mount for import folder.
ext_import_dir="$base_dir/import"

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

# Check for Docker container name.
if [ "$container_name" == "" ]
then
  echo "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify container_name in the config file."
  exit 1;
fi

# Confirm that a CSV folder containing all 12 ontology CSV files is present.
if [ "$csv_dir" == "" ]
then
  echo "Error: Path to CSV files not specified. Either accept the default (./CSV) or specify csv_dir in the config file."
  exit 1;
fi

if [ ! -d "$csv_dir" ]
  then
    echo "Error: no path '$csv_dir' exists. A full set of ontology files must exist at '$csv_dir'"
    exit 1;
fi

# Check for all CSV files in CSV directory.
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
echo "Importing CSV files from $csv_dir into a new database named 'ontology' in the neo4j server hosted in container $container_name."


# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j
IMPORT="$NEO4J"/import

#echo "Stopping neo4j server to go into read_only mode..."
# https://neo4j.com/developer/kb/how-to-properly-shutdown-a-neo4j-database/
#docker exec -u "$neo4j_user" -p "$neo4j_password" "$NEO4J/bin/neo4j stop"
#while [ docker exec -u "$neo4j_user" -p "$neo4j_password" "$NEO4J"/bin/neo4j status ]; do
    #echo "Waiting for Neo4j to stop..."
    #sleep 1
  #done;
#fi

# Copy CSV files to the import folder of the neo4j instance, which is an external bind mount.
cp -R "$csv_dir" "$ext_import_dir"

# Connect to the neo4j instance and import CSVs.
# $IMPORT is the folder on the local machine that is the external bind mount for the import folder of the neo4j instance.
docker exec -it $container_name "$NEO4J"/bin/neo4j-admin database import full --verbose \
  --nodes=Semantic="$IMPORT"/TUIs.csv \
  --nodes=Concept="$IMPORT"/CUIs.csv \
  --nodes=Code="$IMPORT"/CODEs.csv \
  --nodes=Term="$IMPORT"/SUIs.csv \
  --nodes=Definition="$IMPORT"/DEFs.csv \
  --relationships=ISA_STY="$IMPORT"/TUIrel.csv \
  --relationships=STY="$IMPORT"/CUI-TUIs.csv \
  --relationships="$IMPORT"/CUI-CUIs.csv \
  --relationships=CODE="$IMPORT"/CUI-CODEs.csv \
  --relationships="$IMPORT"/CODE-SUIs.csv \
  --relationships=PREF_TERM="$IMPORT"/CUI-SUIs.csv \
  --relationships=DEF="$IMPORT"/DEFrel.csv \
  --skip-bad-relationships \
  --skip-duplicate-nodes \
  ontology
