#!/bin/bash
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# Build Container script that:
# 1. Reads a configuration file.
# 2. Builds a Neo4j Docker container (Community Edition)
# 3. Mounts a Neo4j data directory.


echo
echo "==================== UBKG Neo4j Deployment for hs-ontology-api ===================="
echo


# Name of the configuration file.
config_file="container.cfg"
# Name of the Docker container.
container_name="ubkg-neo4j"

# Image with tag
docker_image_name="hubmap/ubkg-neo4j:current-release"

# Neo4j connection
neo4j_user="neo4j"
neo4j_password=""
ui_port="7474"
bolt_port="7687"
read_mode="read-only"

# Default paths for external bind mounts.
# Get relative path to current directory.
base_dir="$(dirname -- "${BASH_SOURCE[0]}")"
# Convert to absolute path.
base_dir="$(cd -- "$base_dir" && pwd -P;)"
db_mount_dir="$base_dir"/data


# Validate config items
function validate_config() {
    if [ ! -e $config_file ]; then
        echo "Missing config file (relative path to DIR of script): $config_file"
        exit -1
    else
        source "$config_file";
    fi

    # Read/Write mode
    if [ "$read_mode" == "" ]; then
        echo "Error: no value for 'read_mode' specified in $config_file. Either accept the default (read-only) or specify a value."
        echo "Options are 'read-write' and 'read-only'."
        exit 1;
    fi

    if ! ([[ "$read_mode" == "read-only" ]] || [[ "$read_mode" == "read-write" ]]); then
        echo "Error: invalid value for 'read_mode'. Options are 'read-write' and 'read-only'."
        exit 1;
    fi

    if [ "$neo4j_user" == "" ]; then
        echo "Error: no value for neo4j_user. Either accept the default (neo4j) or specify a value in the config file."
        exit 1;
    fi

    # Neo4j password requirements
    if [ "$neo4j_password" == "" ]; then
        echo "Error: no neo4j_password specified in config file."
        exit 1;
    fi

    # The password must contain at least one alphabetic and one numeric character and minimum 8 characters
    if ! [[ ${#neo4j_password} -ge 8 ]]; then
        echo "Error: password must be a minumum of 8 characters long."
        exit 1;
    fi
    
    if ! [[ "$neo4j_password" =~ [A-Za-z] ]]; then
        echo "Error: password must contain at least one alphabetic character."
        exit 1;
    fi
    
    if ! [[ "$neo4j_password" =~ [0-9] ]]; then
        echo "Error: password must contain at least one numeric character."
        exit 1;
    fi

    # Integer browser port
    if ! [[ "$ui_port" =~ ^[0-9]+$ ]]; then
        echo "Error: non-integer neo4j browser port. Either accept the default (7474) or specify an integer for ui_port in the config file."
        exit 1;
    fi

    if [ "$ui_port" == "" ]; then
        echo "Error: null neo4j browser port. Either accept the default (7474) or specify an integer for ui_port in the config file."
        exit 1;
    fi

    # Integer bolt port
    if ! [[ "$bolt_port" =~ ^[0-9]+$ ]]; then
        echo "Error: non-integer bolt port. Either accept the default (7687) or specify an integer for bolt_port in the config file."
        exit 1;
    fi
    
    if [ "$bolt_port" == "" ]; then
        echo "Error: null bolt port. Either accept the default (7687) or specify an integer for bolt_port in the config file."
        exit 1;
    fi

    ont_db_dir="$db_mount_dir"/databases/neo4j
    if [ ! -d "$ont_db_dir" ]; then
        echo "Error: no data directory found. A full set of Neo4j database files must exist at '$ont_db_dir'."
        exit 1
    fi
}


# Container management
if [[ "$1" != "start" && "$1" != "stop" && "$1" != "down" ]]; then
    echo "Unknown command '$1', specify one of the following: start|stop|down"
    echo
    echo "Usage: ./docker-deployment.sh [start|stop|down]"
    echo
else
    if [ "$1" = "start" ]; then
        validate_config

        echo "Starting Docker container $container_name"

        # Create container with external bind mounts for data, import, and logs.
        # The network name data_distillary_network matches an entry in the
        # ubkg_api docker-compose.yml file, for the ubkg_api app to communicate with this server.
        docker run -d \
             -p "$ui_port":7474 \
             -p "$bolt_port":7687 \
             -v "$db_mount_dir":/usr/src/app/neo4j/data \
             -v "$base_dir/logs":/usr/src/app/neo4j/logs \
             --env NEO4J_USER="$neo4j_user" \
             --env NEO4J_PASSWORD="$neo4j_password" \
             --env UI_PORT="$ui_port" \
             --env BOLT_PORT="$bolt_port" \
             --env RW_MODE="$read_mode" \
             --restart=always \
             --name "$container_name" \
             "$docker_image_name" | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"

            #grep -v commands above hide confusing messages coming from inside the container about
            #how to connect to Neo4j potentially only from inside the container if the port number
            #are not the defaults for the external mappings
    elif [ "$1" = "stop" ]; then
        echo "Stopping Docker container $container_name"

        docker stop "$container_name"
    elif [ "$1" = "down" ]; then
        echo "Stopping then deleting Docker container $container_name"

        docker stop "$container_name"
        docker rm "$container_name"
    fi
fi


