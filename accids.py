#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create bcp records for ACC taxIds for LocusLink load.
#  
# Input:
#
#	None
#
# Assumes:
#
#	taxId ${RADARDB}..EntrezGeneBucket0 exists
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
import getopt
import accessionlib
import db
import mgi_utils
import loadlib

#globals

referenceKey = os.environ['REFERENCEKEY']	# _Refs_key of Reference
mgiTypeKey = os.environ['MARKERTYPEKEY']	# _Marker_Type_key of a Marker

accFileName = None
accrefFileName = None
diagFileName = None
diagFile = ''

accKey = 0	# primary key for Accession Numbers
userKey = 0	# primary key for DB User
taxId = None
datadir = None

loaddate = loadlib.loaddate 	# Creation/Modification date for all records
radar = os.environ['RADARDB']

def showUsage():
	'''
	# requires:
	#
	# effects:
	# Displays the correct usage of this program and exits
	# with status of 1.
	#
	# returns:
	'''
 
	usage = 'usage: %s -S server\n' % sys.argv[0] + \
		'-D database\n' + \
		'-U user\n' + \
		'-P password file\n'
	exit(1, usage)
 
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

	db.useOneConnection()
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
	global accKey, userKey, taxId, datadir
 
	try:
		optlist, args = getopt.getopt(sys.argv[1:], 'S:D:U:P:T:O:')
	except:
		showUsage()
 
	#
	# Set server, database, user, passwords depending on options
	# specified by user.
	#
 
	server = None
	database = None
	user = None
	password = None
	taxId = None
	datadir = None
 
	for opt in optlist:
                if opt[0] == '-S':
                        server = opt[1]
                elif opt[0] == '-D':
                        database = opt[1]
                elif opt[0] == '-U':
                        user = opt[1]
                elif opt[0] == '-P':
                        password = string.strip(open(opt[1], 'r').readline())
                elif opt[0] == '-O':
                        datadir = opt[1]
                elif opt[0] == '-T':
                        taxId = opt[1]
                else:
                        showUsage()
 
	# User must specify Server, Database, User and Password
	if server is None or database is None or user is None or password is None or taxId is None or datadir is None:
		showUsage()
 
	# Initialize db.py DBMS parameters
	db.set_sqlLogin(user, password, server, database)
	db.useOneConnection(1)
 
        # Log all SQL
        db.set_sqlLogFunction(db.sqlLogAll)

        diagFileName = datadir + '/accids.diagnostics'
        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        # Set Log File Descriptor
        db.set_sqlLogFD(diagFile)

        diagFile.write('Start Date/Time: %s\n' % (mgi_utils.date()))
        diagFile.write('Server: %s\n' % (server))
        diagFile.write('Database: %s\n' % (database))
        diagFile.write('User: %s\n' % (user))
    
        accFileName = datadir +  '/ACC_Accession.bcp'
        accrefFileName = datadir +  '/ACC_AccessionReference.bcp'

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

	userKey = loadlib.verifyUser(user, 0, None)

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

	results = db.sql('select _Object_key, _LogicalDB_key, accID, private ' + \
		'from %s..WRK_EntrezGene_Bucket0 where taxID = %s' % (radar, taxId), 'auto')

	for r in results:

		prefixPart, numericPart = accessionlib.split_accnum(r['accID'])
		accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
			% (accKey, r['accID'], mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], r['_Object_key'], mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
		accrefFile.write('%d|%s|%s|%s|%s|%s\n' % (accKey, referenceKey, userKey, userKey, loaddate, loaddate))
		accKey = accKey + 1

#
# Main
#

init()
writeAccBCP()
exit(0)

