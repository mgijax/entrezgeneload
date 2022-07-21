'''
#
# Purpose:
#
#	Create input record for Annotation load using Alliance file
#       using HGNC (7) and DOIID (4)
#       only load association type = is_implicated_in (6)
#  
# Output:
#
#	${ANNOTATIONFILE}
#
# Processing:
#
# History:
#
# 07/21/2022	lec
# 	- wts2-646/Switch load of Human gene to disease associations to use the Alliance file
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

for line in allianceFile.readlines():
        tokens = str.split(line[:-1], '\t')
        hgncid = tokens[3]
        associationType = tokens[5]
        doid = tokens[6]

        annotFile.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\t%s\n' \
                % (doid, hgncid, reference, evidenceCode, editor, loaddate, logicalDB))

diagFile.write('\n\nEnd Date/Time: %s\n' % (loaddate))
diagFile.close()
annotFile.close()
allianceFile.close()
db.useOneConnection(0)

