# https://github.com/hubmapconsortium/neo4j-docker/blob/master/neo4j-image/Dockerfile
FROM hubmap/neo4j-image:4.2.5

# Change directory
WORKDIR /usr/src/app

RUN echo "Copying configuration files to image..."
# Copy files from host to image
COPY start.sh .
COPY set_constraints.cypher .
COPY neo4j.conf /usr/src/app/neo4j/conf

# Change directory
WORKDIR /usr/src/app/neo4j/bin

# Make the start script executable
RUN chmod +x /usr/src/app/start.sh

# The EXPOSE instruction informs Docker that the container 
# listens on the specified network ports at runtime
# on the default ports, Web UI:7474  Bolt:7687
EXPOSE 7474 7687


# Start the neo4j server when container spins up
CMD ["/usr/src/app/start.sh"]
