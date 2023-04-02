if [ -z "$1" ]
  then
    echo "    Must provide a single parameter containing the password that will be used by neo4j."; echo "    Like ./run-local.sh mypasswd"; exit 1;
fi

#calculate the directory where the csv files are based of of the location of this script
#we expect this sript to be in a directory called "docker" and the
#csv files to be at a relative location of ../neo4j/import
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BASE_DIR="${SCRIPT_DIR::-6}"
IMPORT_DIR="$BASE_DIR"neo4j/import

#check for the existence of the import directory
if [ ! -d "$IMPORT_DIR" ]
  then
    echo "   A directory containing csv files for import into the database was expected, but not found, at $IMPORT_DIR";  exit 1;
fi

#check for the existence of one of the csv files
if [ ! -f "$IMPORT_DIR"/CODEs.csv ]
  then
      echo "   The file CODEs.csv was not found in $IMPORT_DIR"
      echo "   It was expeced along with other csv import files"
fi

docker run -it \
       -p7474:7474 \
       -p7687:7687 \
       -v "$IMPORT_DIR":/usr/src/app/neo4j/import \
       --env NEO4J_USER=neo4j \
       --env NEO4J_PASSWORD="$1" \
       ubkg-neo4j-local
