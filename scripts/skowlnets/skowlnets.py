#!/usr/bin/env python
# coding: utf-8

# # SimpleKnowledge to OWLNETS converter
# 
# Uses the input spreadsheet for the SimpleKnowledge Editor to generate a set of text files that comply with the
# OWLNETS format, as described in https://github.com/callahantiff/PheKnowLator/blob/master/notebooks
# /OWLNETS_Example_Application.ipynb.
# 
# User guide to build the SimpleKnowledge Editor spreadsheet:
# https://docs.google.com/document/d/1wjsOzJYRV2FRehX7NQI74ZKRXvH45l0QmClBBF_VypM/edit?usp=sharing

# SimpleKnowledge to OWLNETS converter

# Uses the input spreadsheet for the SimpleKnowledge Editor to generate text files that comply with the OWLNETS format.

# This script is designed to align with the PheKnowLator logic executed in the build_csv.py script--e.g., outputs
# to owlnets_output, etc.

import argparse
import sys
import pandas as pd
import numpy as np
import os
import glob
import logging.config

# JAS FEB 2023
# Replaced the light version of the codeReplacements function with the one from OWLNETS-UMLS-GRAPH-12.py.


def codeReplacements(x):
    # JAS 15 Nov 2022 - Refactor

    # This function converts strings that correspond to either codes or CUIs for concepts to a format
    # recognized by the knowledge graph.
    #
    # For most concepts this format is:
    # <SAB><space><code>
    # There are a number of special cases, which are handled below.

    # The argument x is a Pandas Series object containing information on either:
    #  a node (subject or object)
    #  a dbxref

    # 1. Account for special cases of
    #   a. MONDO
    #   b. EDAM
    #   c. JAS 13 JAN 2023 - UNIPROT
    # 2. Consolidate some string handling.
    # 3. Break up the original string replacement for ease of debugging.

    # Convert the code string to the CodeID format.
    # This is sufficient for all cases except EDAM, for which underscores will be restored.
    ret = x.str.replace(':', ' ').str.replace('#', ' ').str.replace('_', ' ').str.split('/').str[-1]

    # Convert SABs to expected values.
    # NCI
    ret = ret.str.replace('NCIT ', 'NCI ', regex=False)

    # MSH
    ret = ret.str.replace('MESH ', 'MSH ', regex=False)
    # GO
    ret = ret.str.replace('GO ', 'GO GO:', regex=False)
    # NCBI
    ret = ret.str.replace('NCBITaxon ', 'NCBI ', regex=False)
    # UMLS
    ret = ret.str.replace('.*UMLS.*\s', 'UMLS ', regex=True)
    # SNOMED
    ret = ret.str.replace('.*SNOMED.*\s', 'SNOMEDCT_US ', regex=True)
    # HP
    ret = ret.str.replace('HP ', 'HPO HP:', regex=False)
    # FMA
    ret = ret.str.replace('^fma', 'FMA ', regex=True)
    # HGNC
    ret = ret.str.replace('Hugo.owl HGNC ', 'HGNC ', regex=False)
    ret = ret.str.replace('HGNC ', 'HGNC HGNC:', regex=False)
    ret = ret.str.replace('gene symbol report?hgnc id=', 'HGNC HGNC:', regex=False)

    # Special case:
    # MONDO identifies genes with IRIs in format
    # http://identifiers.org/hgnc/<id>
    # Convert to HGNC HGNC:<id>
    ret = np.where((OWL_SAB == 'MONDO' and x.str.contains('http://identifiers.org/hgnc')),
                   'HGNC HGNC:' + x.str.split('/').str[-1], ret)

    # Special cases: EDAM codes.
    # 1. When obtained from edge file for source or object nodes, EDAM IRIs are in the format
    #    http://edamontology.org/<domain>_<id>
    #    e.g., http://edamontology.org/format_3750
    # 2. When obtained from node file for dbxref, EDAM codes are in the format
    #    EDAM:<domain>_<id>

    # Force the SAB to be EDAM and restore the underscore delimiter between domain and id.
    # ret = np.where((x.str.contains('http://edamontology.org')),
    # 'EDAM ' + x.str.replace(':', ' ').str.replace('#', ' ').str.split('/').str[-1]
    # , ret)

    # Case 2
    ret = np.where((x.str.contains('EDAM')), x.str.split(':').str[-1], ret)
    # Case 1
    ret = np.where((x.str.contains('edam')), 'EDAM ' + x.str.replace(' ', '_').str.split('/').str[-1], ret)

    # JAS JAN 2023 - Special case: Glyco Glycan
    # Glycan node IRIs are in format:
    # http://purl.jp/bio/12/glyco/glycan#(code delimited with underscore)
    # Force the SAB to be GLYCO.GLYCAN and restore the underscore delimiter between domain and id.
    ret = np.where((x.str.contains('http://purl.jp/bio/12/glyco/glycan')), 'GLYCO.GLYCAN ' + x.str.replace(' ', '_').str.replace('#', '/').str.split('/').str[-1], ret)

    # JAS JAN 2023 - Special case: Glyco Conjugate
    # Glycan node IRIs are in format:
    # http://purl.jp/bio/12/glyco/conjugate#(code delimited with underscore)
    # Force the SAB to be GLYCO.CONJUGATE and restore the underscore delimiter between domain and id.
    ret = np.where((x.str.contains('http://purl.jp/bio/12/glyco/conjugate')),
                   'GLYCO.CONJUGATE ' + x.str.replace(' ', '_').str.replace('#', '/').str.split('/').str[-1], ret)

    # JAS JAN 2023 - Special case: NCBI's GENE database
    # Node IRIs for genes in NCBI GENE are in format
    # http: // www.ncbi.nlm.nih.gov / gene / 19091
    # FEB 2023
    # NCBI Gene IDs are currently stored in the NCI SAB obtained from UMLS, with code IDs that
    # prepend a 'C' to the Gene ID.
    # Until we ingest NCBI Gene directly, map to NCI format.
    ret = np.where(x.str.contains('http://www.ncbi.nlm.nih.gov/gene'), 'NCI' + 'C' + x.str.split('/').str[-1], ret)

    # ret = np.where(x.str.contains('http://www.ncbi.nlm.nih.gov/gene'), 'GENE' + x.str.split('/').str[-1], ret)

    # JAS JAN 2023 - Special case: NIFSTD
    # As with EDAM, Node IRIs for codes from NIFSTD show domains--e.g.,
    # http://uri.neuinfo.org/nif/nifstd/nlx_149264, where "nlx" is the domain
    # Unify codes under the SAB NIFSTD and restore the underscore delimiter between domain and id.
    ret = np.where(x.str.contains('http://uri.neuinfo.org/nif/nifstd'), 'NIFSTD' + x.str.replace(' ', '_').str.split('/').str[-1], ret)

    # Special case:
    # HGNC codes in expected format--i.e., that did not need to be converted above.
    # This is currently the case for UNIPROTKB.
    ret = np.where(x.str.contains('HGNC HGNC:'), x, ret)

    # JAS 13 JAN 2023 - Special case: UNIPROT (not to be confused with UNIPROTKB).
    # The Uniprot OWL node IRIs do not conform to OBO, so set SAB explicitly.
    ret = np.where(x.str.contains('http://purl.uniprot.org'), 'UNIPROT ' + x.str.split('/').str[-1], ret)

    # JAS JAN 2023 - Special case: HRAVS
    ret = np.where(x.str.contains('http://purl.humanatlas.io/valueset/'),'HRAVS '+ x.str.split('/').str[-1], ret)
    ret = np.where(x.str.contains('Thesaurus.owl'), 'NCI ' + x.str.split('#').str[-1], ret)

    # JAS 12 JAN 2023 - Force SAB to uppercase.
    # The CodeId will be in format SAB <space> <other string>, and <other string> can be mixed case.
    # <other string> can also have spaces.
    # ret is now a numpy array.
    # Split each element; convert the SAB portion to uppercase; and rejoin.
    for idx, x in np.ndenumerate(ret):
        x2 = x.split(sep= ' ',maxsplit=1)
        x2[0] = x2[0].upper()
        ret[idx] = ' '.join(x2)
    return ret

    # original code
    # return x.str.replace('NCIT ', 'NCI ', regex=False).str.replace('MESH ', 'MSH ', regex=False) \
    # .str.replace('GO ', 'GO GO:', regex=False) \
    # .str.replace('NCBITaxon ', 'NCBI ', regex=False) \
    # .str.replace('.*UMLS.*\s', 'UMLS ', regex=True) \
    # .str.replace('.*SNOMED.*\s', 'SNOMEDCT_US ', regex=True) \
    # .str.replace('HP ', 'HPO HP:', regex=False) \
    # .str.replace('^fma', 'FMA ', regex=True) \
    # .str.replace('Hugo.owl HGNC ', 'HGNC ', regex=False) \
    # .str.replace('HGNC ', 'HGNC HGNC:', regex=False) \
    # .str.replace('gene symbol report?hgnc id=', 'HGNC HGNC:', regex=False)


# Parse an argument that identifies the version of the UMLS in Neptune from which to build
# the CSV files.
class RawTextArgumentDefaultsHelpFormatter(
    argparse.ArgumentDefaultsHelpFormatter,
    argparse.RawTextHelpFormatter
):
    pass


parser = argparse.ArgumentParser(
    description='Builds ontology files in OWLNETS format from a spreadsheet in SimpleKnowledge format.',
    formatter_class=RawTextArgumentDefaultsHelpFormatter)
parser.add_argument("skfile", help="SimpleKnowledge spreadsheet name")
parser.add_argument("sab", help="Name of SimpleKnowledge ontology")
# JAS FEB 2023 Moved the expected location of the SimpleKnowledge file to a subdirectory in the OWL path.
parser.add_argument("-s", "--sk_dir", type=str, default='./owl',
                    help="parent directory of the directory that contains the SimpleKnowledge spreadsheet")
parser.add_argument("-l", "--owlnets_dir", type=str, default="./owlnets_output",
                    help="directory containing the owlnets output directories")
args = parser.parse_args()

# Use existing logging from build_csv.
# Note: To run this script directly as part of development or debugging
# (i.e., instead of calling it from build_csv.py), change the relative paths as follows:
# log_config = '../builds/logs'
# glob.glob('../**/logging.ini'...

log_dir, log, log_config = 'builds/logs', 'pkt_build_log.log', glob.glob('**/logging.ini', recursive=True)
logger = logging.getLogger(__name__)
logging.config.fileConfig(log_config[0], disable_existing_loggers=False, defaults={'log_file': log_dir + '/' + log})


def print_and_logger_info(message: str) -> None:
    print(message)
    logger.info(message)

# JAS FEB 2023 Moved the expected location of the SimpleKnowledge file from the inport director to a subdirectory
# of the OWL folder.
# Read input spreadsheet.
input_path: str = os.path.join(args.sk_dir, args.sab, args.skfile)
try:
    df_sk = pd.read_excel(input_path, sheet_name='SimpleKnowledgeEditor')
except FileNotFoundError:
    err = 'Missing input spreadsheet: ' + os.path.abspath(input_path)
    raise SystemExit(err)

# Build OWLNETS text files.
# The OWLNETS format represents ontology data in a TSV in format:

# subject <tab> predicate <tab> object
#
# where:
#   subject - code for node in custom ontology
#   predicate - relationship
#   object: another code in the custom ontology
#
#  (In canonical OWLNETS, the relationship is a URI for a relation 
#  property in a standard OBO ontology, such as RO.) For custom
#  ontologies such as HuBMAP, we use custom relationship strings.)
owlnets_path: str = os.path.join(args.owlnets_dir, args.sab)
os.system(f"mkdir -p {owlnets_path}")

edgelist_path: str = os.path.join(owlnets_path, 'OWLNETS_edgelist.txt')
print_and_logger_info('Building: ' + os.path.abspath(edgelist_path))

with open(edgelist_path, 'w') as out:
    out.write('subject' + '\t' + 'predicate' + '\t' + 'object' + '\n')

    # Each column after E in the spreadsheet (isa, etc.) represents a type of
    # subject-predicate_object relationship.
    #   1. Column E represents the dbxrefs. The dbxrefs field is an optional list of references to
    #      concept IDs in other vocabularies, delimited
    #      with a comma between SAB and ID and a pipe between entries--e.g,
    #      SNOMEDCT_US:999999,UMLS:C99999. This list should be exploded and then subClassOf relationship rows
    #      written.
    #   2. Column F represents the isa relationship. This corresponds to a isa relationship within the
    #      custom ontology.
    #   3. Columns after F represent relationships other than isa in the custom ontology.

    # Cells in relationship columns contain comma-separated lists of object nodes.

    # Thus, a relationship cell, in general, represents a set of subject-predicate-object
    # relationships between the concept in the "code" cell and the concepts in the relationship
    # cell.

    for index, row in df_sk.iterrows():

        if index >= 0:  # non-header
            subject = str(row['code'])

            # JAS 8 NOV 2022: Changed start of range from 4 to 5 the "dbxref" column.
            # dbxref is not a custom relationship, but an equivalence class.
            for col in range(5, len(row)):
                # Obtain relationship (predicate)
                if col == 5:
                    # The OWLNETS-UMLS-GRAPH script converts subClassOf into isa and inverse_isa relationships.
                    predicate_uri = "subClassOf"

                else:
                    # custom relationship (predicate)
                    colhead = df_sk.columns[col]
                    # predicate_uri = colhead[colhead.find('(')+1:colhead.find(')')]
                    predicate_uri = colhead

                # Obtain codes in the proposed ontology for object concepts involved
                # in subject-predicate-object relationships.
                objects = row.iloc[col]

                if not pd.isna(objects):

                    listobjects = objects.split(',')
                    for obj in listobjects:
                        if col == 4:
                            objcode = codeReplacements(obj)
                        else:
                            # Match object terms with their respective codes (Column A),
                            # which will result in a dataframe of one row.
                            match = df_sk[df_sk['term'] == obj]
                            if match.size == 0:
                                err = 'Error: row for \'' + subject + '\' indicates relationship \'' + predicate_uri
                                err = err + '\' with node \'' + obj + '\', but this node is not defined in the \'term\' '
                                err = err + 'column. (Check for spelling and case of node name.)'
                                print_and_logger_info(err)
                            objcode = match.iloc[0, 1]

                        out.write(subject + '\t' + predicate_uri + '\t' + str(objcode) + '\n')

# NODE METADATA
# Write a row for each unique concept in the 'code' column.

node_metadata_path: str = os.path.join(owlnets_path, 'OWLNETS_node_metadata.txt')
print_and_logger_info('Building: ' + os.path.abspath(node_metadata_path))

with open(node_metadata_path, 'w') as out:
    out.write(
        'node_id' + '\t' + 'node_namespace' + '\t' + 'node_label' + '\t' + 'node_definition' + '\t' + 'node_synonyms' + '\t' + 'node_dbxrefs' + '\n')

    for index, row in df_sk.iterrows():
        if index >= 0:  # non-header
            node_id = str(row['code'])
            node_namespace = 'HUBMAP'
            node_label = str(row['term'])
            node_definition = str(row['definition'])

            node_synonyms = str(row['synonyms'])
            # The synonym field is an optional pipe-delimited list of string values.
            if node_synonyms in (np.nan, 'nan'):
                node_synonyms = ''

            node_dbxrefs = str(row['dbxrefs'])
            if node_dbxrefs in (np.nan, 'nan'):
                node_dbxrefs = ''

            out.write(
                node_id + '\t' + node_namespace + '\t' + node_label + '\t' + node_definition + '\t' + node_synonyms + '\t' + node_dbxrefs + '\n')

# RELATION METADATA
# Create a row for each type of relationship.

relation_path: str = os.path.join(owlnets_path, 'OWLNETS_relations.txt')
print_and_logger_info('Building: ' + os.path.abspath(relation_path))

with open(relation_path, 'w') as out:
    # header
    out.write(
        'relation_id' + '\t' + 'relation_namespace' + '\t' + 'relation_label' + '\t' + 'relation_definition' + '\n')

    # The first relationship is a subClassOf, which the OWLNETS-UMLS-GRAPH script will convert to an isa.
    out.write('subClassOf' + '\t' + 'HUBMAP' + '\t' + 'subClassOf' + '\t' + '' + '\n')

    # The values from the dbxref column correspond to a pipe-delimited, colon-delimited set
    # of concepts in other vocabularies in the onotology. These will be expanded to a set of
    # subClassOf relationships to establish the polyhierarchy.

    # Establish the remaining custom relationships.
    for col in range(6, len(df_sk.columns)):
        colhead = df_sk.columns[col]

        if colhead != 'dbxrefs':
            # predicate_uri = colhead[colhead.find('(')+1:colhead.find(')')]
            predicate_uri = colhead
            relation_namespace = args.sab
            relation_definition = ''
            # out.write(predicate_uri + '\t' + relation_namespace + '\t' + label + '\t' + relation_definition + '\n')
            out.write(
                predicate_uri + '\t' + relation_namespace + '\t' + predicate_uri + '\t' + relation_definition + '\n')
