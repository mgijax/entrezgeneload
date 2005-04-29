#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create input record for Annotation load
#  
# Input:
#
#	None
#
# Assumes:
#
#	${RADARDB}..WRK_EntrezGene_Bucket0 exists
#
# Output:
#
#	${ANNOTATIONFILE}
#
# Processing:
#
# History:
#
# 	04/28/2005	lec
#	- TR 3853, OMIM
#
'''

import sys
import os
import string
import db
import mgi_utils
import loadlib

#globals

datadir = os.environ['DATADIR']
radar = os.environ['RADARDB']
editor = os.environ['CREATEDBY']
reference = os.environ['ANNOTREFERENCE']
logicalOMIM = os.environ['LOGICALOMIMKEY']
evidenceCode = 'TAS'
logicalDB = 'Entrez Gene'

annotFileName = os.environ['ANNOTATIONFILE']
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
 
	global annotFile, diagFile
 
        # Log all SQL
        db.set_sqlLogFunction(db.sqlLogAll)

        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        # Set Log File Descriptor
        db.set_sqlLogFD(diagFile)

	try:
		annotFile = open(annotFileName, 'w')
	except:
		exit(1, 'Could not open file %s\n' % annotFileName)
		
	db.useOneConnection(1)

def writeAnnotations():
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

	# OMIM ids currently stored in MGI

        db.sql('select accID into #omim from ACC_Accession where _MGIType_key = 13 and _LogicalDB_key = %s' % (logicalOMIM), None)
	db.sql('create index idx1 on #omim(accID)', None)

	#
	# select OMIM disease annotations...
	# those OMIM ids in the MIM table that don't also exist in the Gene Info table
	# those OMIM disease ids that are stored in MGI (in the OMIM vocabulary)
	#

	results = db.sql('select m.geneID, m.mimID ' + \
		'from %s..DP_EntrezGene_MIM m ' % (radar) + \
		'where not exists (select 1 from %s..DP_EntrezGene_DBXRef e ' % (radar) + \
		'where m.geneID = e.geneID ' + \
		'and m.mimID = substring(e.dbXrefID,5,30)) ' + \
		'and exists (select 1 from #omim o where m.mimID = o.accID) ' + \
		'order by geneID', 'auto')

	for r in results:
	    annotFile.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\t%s\n' % (r['mimID'], r['geneID'], reference, evidenceCode, editor, loaddate, logicalDB))

#
# Main
#

init()
writeAnnotations()
exit(0)

