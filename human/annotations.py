'''
#
# Purpose:
#
#	Create input record for Annotation load
#  
# Output:
#
#	${ANNOTATIONFILE}
#
# History:
#
# 06/14/2021    lec
#       wts2-646/Switch load of Human gene to disease associations to use the Alliance file
#       copied from reports_db/daily/MGI_Cov_Human_Gene.py
#
# 03/01/2017	lec
# 	- TR12540/Disease Ontology (DO)
#
# 09/12/2013	lec
#	- TR11484/human/annotation.py/load.csh
#		a) load.csh : annotation.csh was turned OFF/turn back ON
#		b) mim-source "NULL" changed to "-"
#
# 04/28/2005	lec
#	- TR11195/OMIM/add check for annotation type ("phenotype")
#	and source (!= "NULL") to query
#
# 04/28/2005	lec
#	- TR 3853, OMIM
#
'''

import sys
import os
import db
import mgi_utils
import loadlib

#globals

datadir = os.environ['DATADIR']
editor = os.environ['CREATEDBY']
reference = os.environ['DELETEREFERENCE']
evidenceCode = 'TAS'
logicalDB = 'HGNC'

inFile = os.getenv('ALLIANCE_HUMAN_FILE')
fpIn = None

omimToDOLookup = {}

annotFileName1 = os.environ['ANNOTINPUTFILE']
diagFileName = datadir + '/annotation.diagnostics'

annotFile = None
diagFile = None

loaddate = loadlib.loaddate 	# Creation/Modification date for all records

# copied from reports_db/daily/MGI_Cov_Human_Gene.py
assocTypeIncludeList = ['is_implicated_in']
# {HGNC ID: ['mgiID|symbol, ...], ...}
hgncIdToMouseHomDict = {}

def exit(status, message = None):
        '''
        # requires: status, the numeric exit status (integer)
        #           message (string)
        #
        # effects:
        # Print message to stderr and exits
        #
        # returns:
        #
        '''
 
        if message is not None:
                sys.stderr.write('\n' + str(message) + '\n')
 
        try:
                diagFile.write('\n\nEnd Date/Time: %s\n' % (mgi_utils.date()))
                diagFile.close()
                annotFile.close()
        except:
                pass

        db.useOneConnection(0)
        sys.exit(status)
 
def init():
        '''
        # requires: 
        #
        # effects: 
        # 1. Processes command line options
        # 2. Initializes local DBMS parameters
        # 3. Initializes global file descriptors
        #
        # returns:
        #
        '''
 
        global annotFile1, diagFile, fpIn
 
        fpIn = open(inFile, 'r')

        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        try:
                annotFile1 = open(annotFileName1, 'w')
        except:
                exit(1, 'Could not open file %s\n' % annotFileName1)
                
        db.useOneConnection(1)

def writeAnnotations():

        # create DO/HGNC annotations

        doHGNC = []

        for line in fpIn.readlines():

                # ignore comments, and header
                if str.find(line, '#') == 0 or str.find(line, 'Taxon') == 0: 
                        continue
    
                line = str.strip(line)
                tokens = str.split(line, '\t')

                DBObjectID = tokens[3]
                AssociationType = tokens[5]
                DOID = tokens[6]

                if AssociationType not in assocTypeIncludeList:
                        continue

                l = DBObjectID + '|' + DOID

                if l not in doHGNC:
                        annotFile1.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\t%s\n' \
                                % (DOID, DBObjectID, reference, evidenceCode, editor, loaddate, logicalDB))
                        doHGNC.append(l)

        fpIn.close()

#
# Main
#

init()
writeAnnotations()
exit(0)

