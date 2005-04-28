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
editor = os.environ['ANNOTEDITOR']
reference = os.environ['ANNOTREFERENCE']
evidenceCode = 'TAS'

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
		accrefFile.close()
	except:
		pass

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

	#
	# select OMIM disease annotations...
	# those OMIM ids in the MIM table that don't also exist in the Gene Info table
	#

	results = db.sql('select m.geneID, m.mimID ' + \
		'from %s..DP_EntrezGene_MIM m ' % (radar) + \
		'where not exists (select 1 from %s..DP_EntrezGene_DBXRef e ' % (radar) + \
		'where m.geneID = e.geneID ' + \
		'and m.mimID = substring(e.dbXrefID,5,30)) ' + \
		'order by geneID', 'auto')

	for r in results:
	    annotFile.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\n' % (r['mimID'], r['geneID'], reference, evidenceCode, editor, loaddate))

#
# Main
#

init()
writeAnnotations()
exit(0)

