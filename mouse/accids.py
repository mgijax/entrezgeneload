#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create bcp records for ACC tables for LocusLink load.
#  
# Input:
#
#	None
#
# Assumes:
#
#	table ${RADARDB}..EntrezGeneBucket0 exists
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

referenceKey = os.environ['MOUSEREFERENCEKEY']	# _Refs_key of Reference
seqKey = os.environ['LOGICALSEQKEY']		# _LogicalDB_key of a Seq ID
mgiTypeKey = os.environ['MARKERTYPEKEY']	# _Marker_Type_key of a Marker
speciesKey = os.environ['MOUSESPECIESKEY']	# _Organism_key of Mouse

accFileName = os.environ['MOUSEDATADIR'] +  '/ACC_Accession.bcp'
accrefFileName = os.environ['MOUSEDATADIR'] +  '/ACC_AccessionReference.bcp'
diagFileName = os.environ['MOUSEDATADIR'] + '/diagnostics'
diagFile = ''

accKey = 0	# primary key for Accession Numbers
userKey = 0	# primary key for DB User

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
	global accKey, userKey
 
	try:
		optlist, args = getopt.getopt(sys.argv[1:], 'S:D:U:P:')
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
 
	for opt in optlist:
                if opt[0] == '-S':
                        server = opt[1]
                elif opt[0] == '-D':
                        database = opt[1]
                elif opt[0] == '-U':
                        user = opt[1]
                elif opt[0] == '-P':
                        password = string.strip(open(opt[1], 'r').readline())
                else:
                        showUsage()
 
	# User must specify Server, Database, User and Password
	if server is None or database is None or user is None or password is None:
		showUsage()
 
	# Initialize db.py DBMS parameters
	db.set_sqlLogin(user, password, server, database)
	db.useOneConnection(1)
 
        # Log all SQL
        db.set_sqlLogFunction(db.sqlLogAll)

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

def deleteExistingRecords():
	'''
	# requires:
	#
	# effects:
	#	Deletes all Mouse Acc IDs associated with the EntrezGene Reference
	#
	# returns:
	#	nothing
	#
	'''

	db.sql('delete ACC_Accession ' + \
		'from ACC_Accession a, ACC_AccessionReference r, MRK_Marker m ' + \
		'where r._Refs_key = %s ' % (referenceKey) + \
		'and r._Accession_key = a._Accession_key ' + \
		'and a._MGIType_key = %s ' % (mgiTypeKey) + \
		'and a._Object_key = m._Marker_key ' + \
		'and m._Organism_key = %s' % (speciesKey), None)

	db.sql('dump transaction %s with no_log' % (db.get_sqlDatabase()), None)

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

	results = db.sql('select distinct _Object_key, llaccID, _LogicalDB_key, private ' + \
		'from %s..WRK_LLBucket0' % (radar), 'auto')

	for r in results:

		prefixPart, numericPart = accessionlib.split_accnum(r['llaccID'])
		accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
			% (accKey, r['llaccID'], mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], r['_Object_key'], mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
		accrefFile.write('%d|%s|%s|%s|%s|%s\n' % (accKey, referenceKey, userKey, userKey, loaddate, loaddate))
		accKey = accKey + 1

	results = db.sql('select distinct l._Object_key, a.genbankID ' + \
		'from %s..WRK_LLBucket0 l, %s..DP_LLAcc a ' % (radar, radar) + \
		'where l.llaccID = a.geneID ' + \
		'and a.genbankID not like "NM%" ' + \
		'and a.seqType = "m" ' + \
		'and not exists (select 1 from MRK_Acc_View ma ' + \
		'where a.genbankID = ma.accID) ' + \
		'and not exists (select 1 from %s..WRK_LLExcludeSeqIDs s ' % (radar) + \
		'where a.genbankID = s.accID)', 'auto')

	for r in results:

		prefixPart, numericPart = accessionlib.split_accnum(r['genbankID'])
		accFile.write('%d|%s|%s|%s|%s|%d|%s|0|1|%s|%s|%s|%s\n'
			% (accKey, r['genbankID'], prefixPart, mgi_utils.prvalue(numericPart), seqKey, r['_Object_key'], mgiTypeKey, userKey, userKey, loaddate, loaddate))

		accrefFile.write('%d|%s|%s|%s|%s|%s\n' % (accKey, referenceKey, userKey, userKey, loaddate, loaddate))
		accKey = accKey + 1

#
# Main
#

init()
deleteExistingRecords()
writeAccBCP()
exit(0)

