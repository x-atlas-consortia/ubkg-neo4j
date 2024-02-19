# Parent image
FROM redhat/ubi8:8.6

LABEL description="UBKG Neo4j service"

# When trying to run "yum updates" or "yum install", the "system is not registered with an entitlement server" error message is given
# To fix this issue:
RUN echo $'[main]\n\
enabled=0\n\\n\
# When following option is set to 1, then all repositories defined outside redhat.repo will be disabled\n\
# every time subscription-manager plugin is triggered by dnf or yum\n\
disable_system_repos=0\n'\
>> /etc/yum/pluginconf.d/subscription-manager.conf

# Change to directory that contains the Dockerfile
WORKDIR /usr/src/app

# Copy from host to image
COPY . .

# Reduce the number of layers in image by minimizing the number of separate RUN commands
# 1 - Update the package listings
# 2 - Install wget and OpenJRE 11 (packaged with OpenJDK 11)
# 3 - Download neo4j community server
# 4 - Extract neo4j tarball
# 5 - Rename folder to neo4j
# 6 - Download the Apoc 4.2 jar
# 7 - Move the apoc jar to neo4j plugins
# 8 - Remove the downloaded neo4j tarball
# 9 - Clean all yum cache
RUN yum update -y && \
    yum install -y wget java-11-openjdk && \
    wget http://dist.neo4j.org/neo4j-community-4.4.24-unix.tar.gz && \
    tar -zxvf neo4j-community-4.4.24-unix.tar.gz && \
    mv neo4j-community-4.4.24 neo4j && \
    wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.4.0.20/apoc-4.4.0.20-all.jar && \
    mv apoc-4.4.0.20-all.jar neo4j/plugins && \
    rm neo4j-community-4.4.24-unix.tar.gz && \
    yum clean all

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
