#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create bcp records for MGI_Synonym.
#  
# Input:
#
#	None
#
# Assumes:
#
#	${RADARDB}..WRK_EntrezGene_Synonym exists
#
# Output:
#
#	BCP files:
#
#	MGI_Synonym.bcp		Synonym records
#
# Processing:
#
# History:
#
# lec	01/20/2005
#	- created
#
'''

import sys
import os
import string
import db
import mgi_utils
import loadlib

#globals

taxId = os.environ['TAXID']
datadir = os.environ['DATADIR']
radar = os.environ['RADARDB']
referenceKey = os.environ['REFERENCEKEY']	# _Refs_key of Reference
mgiTypeKey = os.environ['MARKERTYPEKEY']	# _Marker_Type_key of a Marker
synTypeKey = os.environ['SYNTYPEKEY']		# _SynonymType_key

synFileName = datadir +  '/MGI_Synonym.bcp'
diagFileName = datadir + '/syns.diagnostics'
diagFile = ''

synKey = 0	# primary key for Synonyms
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
		synFile.close()
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
 
	global synFile, diagFile
	global synKey, userKey
 
        # Log all SQL
        db.set_sqlLogFunction(db.sqlLogAll)

        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        # Set Log File Descriptor
        db.set_sqlLogFD(diagFile)

	try:
		synFile = open(synFileName, 'w')
	except:
		exit(1, 'Could not open file %s\n' % synFileName)
		
	#
	# Get next available primary key
	#

	results = db.sql('select maxKey = max(_Synonym_key) + 1 from MGI_Synonym', 'auto')
	synKey = results[0]['maxKey']

	userKey = loadlib.verifyUser(db.get_sqlUser(), 0, None)

def writeBCP():
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

	global synKey, userKey

	results = db.sql('select _Marker_key, synonym ' + \
		'from %s..WRK_EntrezGene_Synonym ' % (radar) + \
		'where taxID = %s' % (taxId), 'auto')

	for r in results:

		synFile.write('%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n'
			% (synKey, r['_Marker_key'], mgiTypeKey, synTypeKey, referenceKey, r['synonym'], userKey, userKey, loaddate, loaddate))
		synKey = synKey + 1

#
# Main
#

init()
writeBCP()
exit(0)
