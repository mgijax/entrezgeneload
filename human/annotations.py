'''
#
# Purpose:
#
#	Create input record for Annotation load using Alliance file
#       using HGNC and DOIID
#  
# Output:
#
#	${ANNOTATIONFILE}
#
# Processing:
#
# History:
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
logicalOMIM = os.environ['LOGICALOMIMKEY']
evidenceCode = 'TAS'
logicalDB = 'HGNC'

allianceFileName = os.environ['ALLIANCEINPUTFILE']
annotFileName = os.environ['ANNOTINPUTFILE']
diagFileName = datadir + '/annotation.diagnostics'

annotFile = None
diagFile = None

loaddate = loadlib.loaddate 	# Creation/Modification date for all records

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
                allianceFile.close()
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
 
        global annotFile, allianceFile, diagFile
 
        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        try:
                annotFile = open(annotFileName, 'w')
        except:
                exit(1, 'Could not open file %s\n' % annotFileName)
                
        try:
                allianceFile = open(allianceFileName, 'r')
        except:
                exit(1, 'Could not open file %s\n' % allianceFileName)
                
        db.useOneConnection(1)

def writeAnnotations1():
        '''
        # requires:
        #
        # effects:
        #	Creates approrpriate Annotation records
        #
        # returns:
        #	nothing
        #
        '''

        for line in allianceFile.readlines():

            if line[0] == '#' or line[0] == 'Taxon':
                continue

            tokens = str.split(line[:-1], '\t')
            hgncid = tokens[3]
            doid = tokens[6]

            annotFile.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\t%s\n' \
                        % (doid, hgncid, reference, evidenceCode, editor, loaddate, logicalDB))

#
# Main
#

init()
writeAnnotations1()
exit(0)
