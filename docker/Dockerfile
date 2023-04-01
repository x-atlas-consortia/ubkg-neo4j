# https://github.com/hubmapconsortium/neo4j-docker/blob/master/neo4j-image/Dockerfile
# FROM hubmap/neo4j-image:4.2.5

# Change directory
WORKDIR /usr/src/app

RUN echo "Copying configuration files to image..."
# Copy files from host to image
COPY start.sh .
COPY set_constraints.cypher .
COPY neo4j.conf /usr/src/app/neo4j/conf

# Set the environment variable for all subsequent instructions in the build stage
ENV IMPORT=/usr/src/app/neo4j/import

# DEPRECATED
# Load the .csv files to populate neo4j before starting it up.
# This will take some time, but the data will be there when the constraints are run
# in the next docker_compose step 'neo4j-constraints'.
# NOTE: in the repository the 'import/' directory contains one of more directries which contain the UMLS Graph Extracts.
# These change from time to time, and so the .csv files need to be augmented with other onthologies (see 'scipts/').
# So, 'current/' is actually a sybolic link to the current UMLS directory (e.g., 'import/UMLS-Graph-Extracts-2021AA/').
# BIG NOTE: Nice idea, but Docker does not follow symbolic links, so you need to make the link to 'current/' a HARD one
# (e.g., cd import; mv UMLS-Graph-Extracts-2021AA current).
#COPY import/current/*.csv ${IMPORT}/

# NEW
# Copy ontology CSV files to the image from the directory specified in the CSV_DIR environment variable,
# which was passed in the call to docker run.
# The variable should be an absolute file path.
RUN echo "Copying ontology CSV files from ${CSV_DIR to ${IMPORT}"
COPY ${CSV_DIR}/*.csv ${IMPORT}/

# Change directory
WORKDIR /usr/src/app/neo4j/bin

# Run the neo4j-admin import, using the ontology CSVs to specify nodes and edges.
# Name of the database: ontology (via --database flag), which the UBKG API expects.
# NOTE: The NDC nodes (NDCs.csv), and relationships (NDCrel.csv) are not imported at this time.
RUN echo "Running neo4j-admin import"
RUN ./neo4j-admin import --verbose --database=ontology --nodes=Semantic="${IMPORT}/TUIs.csv" --nodes=Concept="${IMPORT}/CUIs.csv"  --nodes=Code="${IMPORT}/CODEs.csv"  nodes=Term="${IMPORT}/SUIs.csv"  nodes=Definition="${IMPORT}/DEFs.csv"  --relationships=ISA_STY="${IMPORT}/TUIrel.csv"  --relationships=STY="${IMPORT}/CUI-TUIs.csv"  --relationships="${IMPORT}/CUI-CUIs.csv"  --relationships=CODE="${IMPORT}/CUI-CODEs.csv"  --relationships="${IMPORT}/CODE-SUIs.csv"  --relationships=PREF_TERM="${IMPORT}/CUI-SUIs.csv"  --relationships=DEF="${IMPORT}/DEFrel.csv"  --skip-bad-relationships  --skip-duplicate-nodes\

# - Install curl
# - Make the start script executable
# - Remove the CSV files
RUN yum install -y curl && \
    chmod +x /usr/src/app/start.sh && \
    rm -rf ${IMPORT}/*


# The EXPOSE instruction informs Docker that the container 
# listens on the specified network ports at runtime
# EXPOSE 7474 7687
EXPOSE ${UI_PORT} ${BOLT_PORT}

# Start the neo4j server when container spins up
CMD ["/usr/src/app/start.sh"]
