#!/bin/pwsh
# -------------------------
# Unified Biomedical Knowledge Graph (UBKG)
# neo4j Docker run script
# PowerShell

# Please consult the README.md file in the root folder of the ubkg-neo4j repository for more information on this script.

param (

    # password for the neo4 account
    # [Parameter(Mandatory=$true)]
    [string]$p,

    # name for the Docker container
    [string]$d ='ubkg-neo4j',

    # username used to connect to the neo4j database
    [string]$u = 'neo4j',

    # path to the directory containing the ontology CSV files
    [string]$c='.\neo4j\import',

    # port to expose the neo4j browser UI on 
    [int]$n=7474,

    # port to expose the neo4j/bolt:// interface on
    [int]$b=7687,

    # the docker tag to use when running
    [string]$t='current-release',

    # help
    [switch]$h = $false

)


###########
# Help function
##########
function Help 
{
   # Display Help
   write-host ""
   write-host "****************************************"
   write-host "HELP: UBKG neo4j Docker container script"
   write-host
   write-host "Syntax: ./run.ps1 [-option1] [argument1] [-option2] [argument2]..."
   write-host "options (in any order)"
   write-host "-p     password for the neo4j account (REQUIRED)"
   write-host "-d     name for the Docker container (OPTIONAL; default = ubkg-neo4j)"
   write-host "-u     username used to connect to the neo4j database (OPTIONAL; default = neo4j)"
   write-host "-c     path to the directory in the local repository containing the ontology CSV files (OPTIONAL; default = ./neo4j/import)"
   write-host "-n     port to expose the neo4j browser/UI on (OPTIONAL; default = 7474)"
   write-host "-b     port to expose the neo4j/bolt:// interface on (OPTIONAL; default = 7687)"
   write-host "-t     the docker tag to use when running, if set to local the local image built by docker/build-local.sh script is used (OPTIONAL: default = <latest released version>"
   write-host "-h     print this help"
   write-host "example: './run.ps1 -p pwd -n 9999' creates a neo4j instance with password 'pwd' and browser port 9999 "
   exit 0
}


if ($h) {
    Help
}


# Set Docker container tag.

if ($t -eq "local") {

    $docker_image_name = "ubkg-neo4j-local"
}
else {
    $docker_image_name = "hubmap/ubkg-neo4j:$t"
}


######
# Validate parameters

# Check for password. (This was not set as an Mandatory parameter to allow the -h parameter to be used by itself.)
if ($p -eq ""){
    write-host "Error: no password for the neo4j account. Specify a password with the -p option."
    exit 1
}

# Check for Docker container name
if ($d -eq ""){
  write-host "Error: no Docker container name. Either accept the default (ubkg-neo4j) or specify the Docker name with the -d option."
  exit 1
}

# Check for neo4j user name
if ($u -eq ""){
  write-host "Error: no neo4j user name. Either accept the default (neo4j) or specify the Docker name with the -u option."
  exit 1
}


# Check for existence of CSV directory.
if (-not(Test-Path -Path $c)){
  write-host "Error: no path '$c' exists. Either accept the default (.\neo4j\import) or specify the the directory that contains the ontology CSV files with the -c option."
  exit 1
}


# Check for CSV files in CSV directory,
$csvlist=@("CODE-SUIs","CODEs","CUI-CODEs","CUI-CUIs","CUI-SUIs","CUI-TUIs","CUIs","DEFrel","DEFs","SUIs","TUIrel","TUIs")
foreach ($csv in $csvlist) {
  $testcsv=$c+"\"+$csv+".csv"
  if (-not(Test-Path -Path $testcsv)){
    write-host "Error: No file named $c+"\"+$csvlist[$i]+".csv" in directory '$c'."
    exit 1
  }
}


write-host ""
write-host "**********************************************************************"
write-host "All 12 required ontology CSV files were found in directory '[$c]'."
write-host ""
write-host "A Docker container for a neo4j instance will be created using the following parameters:"
write-host "  - container name:  $d"
write-host "  - neo4j account name: $u"
write-host "  - neo4j account password: $p"
write-host "  - CSV directory for ontology CSV files: $c"
write-host "  - neo4j browser/UI port: $n"
write-host "  - neo4j bolt port: $b"

# Run Docker container, providing:
# - container name
# - Account information as environment variables
# - browser and bolt ports
# - absolute path to the directory that contains the ontology CSVs. (This will be a bind mount.)
# - neo4j image from Dockerhub
# set up shell
write-host " "
write-host "**************"
write-host "Starting Docker container"


#if a docker container of the same name exists or is running stop and/or delete it
docker stop "$d" 
docker rm "$d" 

docker run -it `
       -p "$n":7474 `
       -p "$b":7687 `
       -v "$c":/usr/src/app/neo4j/import `
       --env NEO4J_USER="$u" `
       --env NEO4J_PASSWORD="$p" `
       --env UI_PORT="$n" `
       --env BOLT_PORT="$b" `
       --name "$d" `
       "$docker_image_name" # | grep --line-buffered -v "Bolt enabled on" | grep --line-buffered  -v "Remote interface available at"

#grep -v commands above hide confusing messages coming from inside the container about
#how to connect to Neo4j potentially only from inside the container if the port number
#are not the defaults for the external mappings

