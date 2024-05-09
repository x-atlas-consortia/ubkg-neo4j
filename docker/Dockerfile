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

# Install OpenJDK 17, Neo4j via a tar file, get apoc jar and put it in place
RUN yum update -y && \
    yum install -y wget java-17-openjdk && \
    wget dist.neo4j.org/neo4j-community-5.11.0-unix.tar.gz && \
    tar -zxvf neo4j-community-5.11.0-unix.tar.gz && \
    mv neo4j-community-5.11.0 neo4j && \
    wget https://github.com/neo4j/apoc/releases/download/5.11.0/apoc-5.11.0-core.jar  && \
    mv apoc-5.11.0-core.jar neo4j/plugins && \
    rm neo4j-community-5.11.0-unix.tar.gz && \
    rm -rf /usr/src/app/neo4j/data/* && \    
    yum clean all

# Change directory
WORKDIR /usr/src/app

RUN echo "Copying configuration files to image..."
# Copy files from host to image
COPY start.sh .
#COPY set_constraints.cypher .
COPY neo4j.conf /usr/src/app/neo4j/conf
COPY neo4j.conf.noauth /usr/src/app/neo4j/conf

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
