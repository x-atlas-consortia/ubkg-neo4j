#tag the latest local build and push it to DockerHub
#this will require a "docker login" first with credentials that allow
#write to the HuBMAP DockerHub org
docker tag ubkg-neo4j-local:latest hubmap/ubkg-neo4j:latest
docker push hubmap/ubkg-neo4j:latest
