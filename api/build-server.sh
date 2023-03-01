#!/bin/sh

VENV=./venv

usage()
{
  echo "Usage: $0 [-r] [-R] [-v] [-c] [-h]"
  echo " -r Run server after building"
  echo " -R Reinstall VENV at ${VENV}"
  echo " -v Verbose output"
  echo " -c Build the client from the openapi spec"
  echo " -h Help"
  exit 2
}

unset VERBOSE
while getopts 'rRvhc' c; do
  echo "Processing $c : OPTIND is $OPTIND"
  case $c in
    r) RUN=true ;;
    R) REINSTALL=true ;;
    v) VERBOSE=true ;;
    c) CLIENT=true ;;
    h|?) usage ;;
  esac
done

shift $((OPTIND-1))

which python3
status=$?
if [[ $status != 0 ]] ; then
    echo '*** Python3 must be installed!'
    exit
fi

if [ $REINSTALL ]; then
  echo "Removing Virtual Environment located at ${VENV}"
  rm -rf ${VENV}
fi

if [[ ! -d ${VENV} ]] ; then
    echo "*** Installing python3 venv to ${VENV}"
    python3 -m pip install --upgrade pip
    python3 -m venv ${VENV}
    source ${VENV}/bin/activate
    pip install -r requirements.txt
    brew install wget
    # https://openapi-generator.tech/docs/generators/python-flask
    brew install openapi-generator
    echo "*** Done installing python3 venv"
fi

echo "*** Using python3 venv in ${VENV}"
source ${VENV}/bin/activate
# JAS FEB 2023 Change reference to spec file from ontology-api-spec to ubkg-api-spec.
openapi-generator generate -i ../ubkg-api-spec.yaml -g python-flask -o .

./update_controller_and_manager.py

touch openapi_server/__init__.py
# JAS 29 Nov 2022 commented out fetches from Docker.
# git checkout -- Dockerfile
# git checkout -- requirements.txt

git add openapi_server/models
git add openapi_server/openapi/openapi.yaml
git add setup.py

# NOTE: setup.py has the wrong version should match that of the .yml file


# JAS FEB 2023 There is a mystery issue in which some task in this script either removes the following items from
# requirements.txt or replaces requirments.txt with a version that does not have it. I cannot find where this
# occurs.
# neo4j == 4.2.1
# openapi-python-client >= 0.10.8

# This causes the build script to fail when run with -r because it is not possible to import neo4j.
# One workaround is to add the above lines to the requirements.txt in the local repo before running the script with -R.
# Alternatively, one can rollback changes to requirements.txt immediately after running the script.

if [ $CLIENT ]; then
  echo "Building Python Client..."
  #rm -rf ./hu-bmap-ontology-api-client
  # https://pypi.org/project/openapi-python-client/
  action='generate'
  if [[ -d ./hu-bmap-ontology-api-client ]] ; then
    action='update'
  fi
  openapi-python-client $action --path ../ontology-api-spec.yaml
fi

if [ $RUN ]; then
  properties_file="openapi_server/resources/app.properties"
  if [[ ! -f ${properties_file} ]] ; then
    echo "To run the server locally, you will need to create a '${properties_file}' file."
  else
    echo "Running server..."
    ./run_server_on_localhost.py
  fi
fi
