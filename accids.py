#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create bcp records for ACC taxIds for EntrezGene load.
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
#	BCP files:
#
#	ACC_Accession.bcp		Accession records
#	ACC_AccessionReference.bcp	Accession/Reference records
#
# Processing:
#
# History:
#
# lec	02/21/2001
#	- created
#
'''

import sys
import os
import string
import accessionlib
import db
import mgi_utils
import loadlib

#globals

taxId = os.environ['TAXID']
datadir = os.environ['DATADIR']
radar = os.environ['RADARDB']
referenceKey = os.environ['REFERENCEKEY']	# _Refs_key of Reference
mgiTypeKey = os.environ['MARKERTYPEKEY']	# _Marker_Type_key of a Marker

accFileName = datadir +  '/ACC_Accession.bcp'
accrefFileName = datadir +  '/ACC_AccessionReference.bcp'
diagFileName = datadir + '/accids.diagnostics'
diagFile = ''

accKey = 0	# primary key for Accession Numbers
userKey = 0	# primary key for DB User

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
		accFile.close()
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
 
	global accFile, accrefFile, diagFile
	global accKey, userKey
 
        # Log all SQL
        db.set_sqlLogFunction(db.sqlLogAll)

        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        # Set Log File Descriptor
        db.set_sqlLogFD(diagFile)

	try:
		accFile = open(accFileName, 'w')
	except:
		exit(1, 'Could not open file %s\n' % accFileName)
		
	try:
		accrefFile = open(accrefFileName, 'w')
	except:
		exit(1, 'Could not open file %s\n' % accrefFileName)
		
	#
	# Get next available primary key
	#

	results = db.sql('select maxKey = max(_Accession_key) + 1 from ACC_Accession', 'auto')
	accKey = results[0]['maxKey']

	userKey = loadlib.verifyUser(db.get_sqlUser(), 0, None)

def writeAccBCP():
	'''
	# requires:
	#
	# effects:
	#	Creates approrpriate BCP records
	#
	# returns:
	#	nothing
	#
	'''

	global accKey, userKey

	# records that require a reference

	results = db.sql('select _Object_key, _LogicalDB_key, accID, private ' + \
		'from %s..WRK_EntrezGene_Bucket0 ' % (radar) + \
		'where taxID = %s and refRequired = 1' % (taxId), 'auto')

	for r in results:

		prefixPart, numericPart = accessionlib.split_accnum(r['accID'])
		accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
			% (accKey, r['accID'], mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], r['_Object_key'], mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
		accrefFile.write('%d|%s|%s|%s|%s|%s\n' % (accKey, referenceKey, userKey, userKey, loaddate, loaddate))
		accKey = accKey + 1

	# records that don't require a reference

	results = db.sql('select _Object_key, _LogicalDB_key, accID, private ' + \
		'from %s..WRK_EntrezGene_Bucket0 ' % (radar) + \
		'where taxID = %s and refRequired = 0' % (taxId), 'auto')

	for r in results:

		prefixPart, numericPart = accessionlib.split_accnum(r['accID'])
		accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
			% (accKey, r['accID'], mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], r['_Object_key'], mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
		accKey = accKey + 1

#
# Main
#

init()
writeAccBCP()
exit(0)

