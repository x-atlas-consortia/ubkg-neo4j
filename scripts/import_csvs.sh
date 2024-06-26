#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# CSV Import script:
# 1. Reads a configuration file of properties of a Docker container hosting an instance of neo4j with an external bind mount.
# 2. Connects to the Docker container.
# 3. Imports a set of CSVs into a new database named ontology.
# 4. Replaces the content of the neo4j database directories (databases and transactions directories) with the content
#    from ontology.
#

# Assumptions:
# 1. The Docker container specified by the configuration file has external bind mounts to folders in the application
#    directory named
#    - data
#    - import
# 2. There is a folder, specified by configuration, that contains the full set of 12 CSV files for the UBKG import.
#    The contents of this folder will be copied into the import bind mount.
# 3. neo4j Community Edition, which can only have one database. Because the neo4j has already been instantiated,
#    the database name has to be neo4j.


###########
# Help function
##########
Help()
{
   # Display Help
   echo ""
   echo "****************************************"
   echo "HELP: UBKG neo4j CSV import script"
   echo "Imports a set of CSVs into a new ontology database in a neo4j instance hosted in a Docker container."
   echo
   echo "Syntax: ./export_db.sh [-c config file]"
   echo "options (in any order)"
   echo "-c   path to config file containing properties for the container (REQUIRED: default='container.cfg'."
   echo "-h   print this help"
   echo "example: './import_csvs.sh' exports the data folder of the container specified in the config file."
   echo "Review container.cfg.example for descriptions of parameters."
}
##############################
# Set defaults.
config_file="container.cfg"
container_name="ubkg-neo4j"

# Default relative paths
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"

# Default folder containing the ontology CSVs.
csv_dir="$base_dir/csv"
# External bind mount to import folder. This must be different than the CSV folder; if a bind mount
# points to a non-empty folder, Docker "obscures" the existing contents.
import_dir="$base_dir/import"

# Default Java max heap setting for CSV import, based on recommendations for
# a machine with 32 GB of RAM working with a neo4j instance with a 27 GB database
# (Data Distillery).
heap_import="1.003g"

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

# CSV directory
if [ ! -d "$csv_dir" ]
  then
    echo "Error: no path '$csv_dir' exists."
    echo "This path must contain a full set of ontology CSVs."
    echo "Either accept the default (./csv) or specify csv_dir in the config file."
    exit 1;
fi

# max Java heap memory
if [ "$heap_import" == "" ]
then
  echo "Error: no value of max Java heap memory for CSV import specified."
  echo "Either accept the default (1.003g) or specify a value for heap_indexing in the configuration file."
  echo "(Run ./neo4j-admin import in the Docker container for recommendations for the size max Java heap memory for your machine.)"
  exit 1;
fi

# Check that all ontology CSV files are in the CSV directory.
csvlist=("CODE-SUIs" "CODEs" "CUI-CODEs" "CUI-CUIs" "CUI-SUIs" "CUI-TUIs" "CUIs" "DEFrel" "DEFs" "SUIs" "TUIrel" "TUIs")
for str in "${csvlist[@]}"; do
  testcsv=$csv_dir$"/"$str$".csv"
  if [ ! -e "$testcsv" ]
  then
    echo "Error: No file named '$str'.csv in '$csv_dir'."
    exit 1;
  fi
done

echo ""
echo "**********************************************************************"
echo "Importing CSV files"
echo " - CSV source directory: $csv_dir "
echo " - Docker container: $container_name."

# Connect to the neo4j instance and import CSVs.

# Neo4j installation directory.
NEO4J=/usr/src/app/neo4j

# The assumption is that the internal import folder has been linked to an external bind mount,
# by means of running build_container.sh and specifying db_mode=external in the config file.
IMPORT="$NEO4J"/import

# Copy CSVs from the csv directory to the import directory. This step is necessary: if you create a container with a
# bind mount to an non-empty directory, the bind mount will obscure the bound directory's existing content--i.e., it will not
# recognize it. To work around this, copy files to the bind mount after it is created.
cp "$csv_dir"/* "$import_dir"

# Delete the specified ubkg database from the external bind mount, if it exists.
echo "Dropping existing ontology database files from external bind mount."
rm -fr "$base_dir/data/databases/data/ontology"
rm -fr "$base_dir/data/transactions/ontology"
echo ""

# MAX HEAP MEMORY
# By default, neo4j uses heuristics to calculate max heap allocation. This can result in an overly large max
# heap size for the import, which will limit memory for other processes and result in slow imports.
# For example, on a MacBook Pro M1 with 32 GB of RAM, importing a set of CSVs with 1824 relationships results in
# a warning like:
# WARNING: heap size 1.705GiB is unnecessarily large for completing this import.
# The abundant heap memory will leave less memory for off-heap importer caches. Suggested heap size is 1.003GiBNodes
#
# The messages then show that each relationship is processed individually--e.g., the import displays messages like this
#Relationship <-- Relationship 6/1824, started 2023-12-13 15:09:21.716+0000

# When there is sufficient memory, the entire group of relationships is processed in parallel--e.g.,
#Relationship <-- Relationship 1-1824/1824, started 2023-12-12 00:07:53.244+0000

# Set heap memory explicitly immediately before import using the JAVA_OPTS environment variable instead of in the
# neo4j.conf file's dbms.memory.heap.initial_size setting.
# The machine building the Docker container from a distribution may not have the same memory
# as the development machine.
# bash -c directs the container to execute the command in the string.

echo "Setting max heap size explicitly to recommended value for import ($heap_import)."
docker exec "$container_name" \
bash -c "export JAVA_OPTS='-server -Xms$heap_import -Xmx$heap_import'"

# Import CSVs.
# Changes to neo4j-admin import for v5:
# 1. "import" is now "database import full"
# 2. "bad_tolerance" parameter, with default of 1000. We will increase this threshold.
# 3. The name of the import database (e.g., neo4j) is now the final argument instead of a --database parameter.
# 4. high-parallel-io=on
# 5. overwrite-destination
docker exec "$container_name" "$NEO4J"/bin/neo4j-admin database import full \
  --verbose \
  --high-parallel-io=on \
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
  --bad-tolerance=10000000 \
  --overwrite-destination\
  neo4j


##############################
# EXPORT IMPORT REPORT TO APPLICATION DIRECTORY.
echo "Exporting import.report to $base_dir"
docker cp "$container_name:/usr/src/app/neo4j/bin/import.report" "$base_dir"
echo "CSV import complete."

