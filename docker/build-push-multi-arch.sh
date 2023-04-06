#by default this script will build and push both x86-64 and arm64
#versions of the image to Docker Hub with the tag "latest"
#
#if given "-rv <version>" argument it will also tag the pushed version
#with the tags "<version>" and "current-release"
#
#to use this script you must first log into DockerHub with the "docker login"
#command using an account with write privileges in the HuBMAP DockerHub organization


release_tags_args=()

if [ "$1" == "-rv" ]
then
  if [ ! "$2" == "" ]
  then
    release_tags_args=(-t hubmap/ubkg-neo4j:$2 -t hubmap/ubkg-neo4j:current-release)
  else
    echo "The -rv option must contain a version to tag the image as the next argument like: ./build-push-multi-arch.sh -rv 3.2.1"
    exit 1
  fi
elif [ ! "$1" == "" ]
then
  echo "$1 is an invalid argument"
  exit 1  
fi

docker buildx build --platform linux/amd64,linux/arm64 --push -t hubmap/ubkg-neo4j:latest "${release_tags_args[@]}" .
