#!/usr/local/bin/python

'''
#
# Purpose:
#
#	TR 3950
#	Create file for nomenload/nomenload.py from Bucket10
#  
# Input:
#
#	None
#
# Output:
#
#	File in format appropriate for nomenload.py
#
#       A tab-delimited file in the format:
#         field 1: Marker Type				(Gene)
#         field 2: Symbol				(BC seq ID)
#         field 3: Name					(cDNA sequence BC seq ID)
#         field 4: Chromosome				(UN)
#         field 5: Marker Status			(Unreviewed)
#         field 6: J: (J:#####)	(J:77000)
#         field 7: List of Synonyms, separated by "|"	(not used)
#         field 8: LogicalDB:Acc ID|LogicalDB:Acc ID|..	(accession ids)
#         field 9: Nomenclature Notes			(EntrezGene Bucket 10 Report - Unpublished GenBank Record)(
#         field 10: Submitted By			(djr)
#
# Processing:
#
# History:
#
# lec	10/15/2002
#	- TR 4154; exclude ll ids which contain genbank IDs which already exist in Nomen/MGD
#
# lec	08/07/2002
#	- created
#
'''

import sys
import os
import string
import getopt
import db
import mgi_utils

#globals

TAB = '\t'
CRT = '\n'
DELIM = '|'
radar = os.environ['RADARDB']

reference = os.environ['MGCJNUM']
mgcFileName = os.environ['MGCFILE']
seqDB = os.environ['MGCSEQDB']
markerType = os.environ['MGCMARKERTYPE']
markerStatus = os.environ['MGCMARKERSTATUS']
chromosome = os.environ['MGCCHROMOSOME']
submitter = os.environ['MGCSUBMITTER']

namePrefix = 'cDNA sequence %s'
notePrefix = 'EntrezGene Bucket 10 Report - Unpublished GenBank Record.  Gene ID:%s.'

mgcFile = ''

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
		'-P password file\n' + \
		'-O MGC file\n'
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
		logFile.close()
		mgcFile.close()
		db.useOneConnection(0)
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
 
	global logFile, mgcFile
 
	try:
		optlist, args = getopt.getopt(sys.argv[1:], 'S:D:U:P:O:N:')
	except:
		showUsage()
 
	#
	# Set server, database, user, passwords depending on options
	# specified by user.
	#
 
	server = ''
	database = ''
	user = ''
	password = ''
 
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
			mgcFileName = opt[1]
                else:
                        showUsage()
 
	# User must specify Server, Database, User and Password
	if server == '' or database == '' or user == '' or password == '' or mgcFileName == '':
		showUsage()
 
	# Initialize db.py DBMS parameters
	db.set_sqlLogin(user, password, server, database)
	# Use one connection
	db.useOneConnection(1)

	try:
		mgcFile = open(mgcFileName, 'w')
	except:
		exit(1, 'Could not open file %s\n' % (mgcFileName))
		
	try:
		logFile = open(os.environ['MOUSEDATADIR'] + '/' + sys.argv[0] + '.log', 'w')
	except:
		exit(1, 'Could not open file %s\n' % (sys.argv[0]))
		
	# Log all SQL
	db.set_sqlLogFunction(db.sqlLogAll)

	# Set Log File Descriptor
	db.set_sqlLogFD(logFile)

def process():

	cmds = []

	# select locusids, genbankids which already exist in MGI
	cmds.append('select distinct ll.geneID, ll.genbankID ' + \
		'into #existingMGC ' + \
		'from %s..WRK_LLBucket10 ll ' % (radar) + \
		'where ll.genbankID like "BC%" ' + \
		'and ll.locusTag is null ' + \
		'and exists (select 1 from ACC_Accession a ' + \
		'where ll.genbankID = a.accID)')

	# select existing NomenDB MGC ids which have additional seq IDs not in NomenDB
	# only if NomenDB status is 'Unreviewed'
	cmds.append('select distinct m.geneID, b.genbankID, a._Object_key ' + \
		'from #existingMGC m, %s..WRK_LLBucket10 b, ' % (radar) + \
		'ACC_Accession a, NOM_Marker_View n ' + \
		'where m.geneID = b.geneID ' + \
		'and m.genbankID = a.accID ' + \
		'and a._MGIType_key = 21 ' + \
		'and a._Object_key = n._Nomen_key ' + \
		'and n.status = "Unreviewed" ' + \
		'and not exists (select 1 from ACC_Accession a2 ' + \
		'where a._Object_key = a2._Object_key ' + \
		'and a2._MGIType_key = 21 ' + \
		'and b.genbankID = a2.accID) ')

	# select new MGC records to add
	cmds.append('select distinct ll.geneID, ll.symbol ' + \
		'into #mgc ' + \
		'from %s..WRK_LLBucket10 ll '% (radar)  + \
		'where ll.genbankID like "BC%" ' + \
		'and ll.locusTag is null ' + \
		'and not exists (select 1 from #existingMGC e ' + \
		'where ll.geneID = e.geneID) ' + \
		'and not exists (select 1 from ACC_Accession a ' + \
		'where ll.genbankID = a.accID)')

	cmds.append('select b.geneID, b.genbankID ' + \
		'from #mgc m, %s..WRK_LLBucket10 b '% (radar)  + \
		'where m.geneID = b.geneID ' + \
		'and b.genbankID like "BC%"')

	cmds.append('select * from #mgc order by geneID')

	results = db.sql(cmds, 'auto')

	# append genbank ids to existing record
	for r in results[1]:
		db.sql('exec ACC_insert %s, ' % (r['_Object_key']) + \
			'"%s", ' % (r['genbankID']) + \
			'%s,"Nomenclature", ' % (os.environ['LOGICALSEQKEY']) + \
			'%s,1,0' % (os.environ['MGCREFSKEY']), None, execute = 1)

	accids = {}
	for r in results[3]:
		key = r['geneID']
		if not accids.has_key(key):
			accids[key] = []
		accids[key].append(r['genbankID'])

	for r in results[4]:

		symbol = ''

		# if the EntrezGene Symbol is "BC" then use it as the MGI symbol
		# else, we'll use the first BC seq id we find

		if string.find(r['symbol'], 'BC') > -1:
			symbol = r['symbol']

		accidstr = ''
		for a in accids[r['geneID']]:
			accidstr = accidstr + seqDB + ':' + a + DELIM

			if symbol == '' and string.find(a, 'BC') > -1:
				symbol = a

		name = namePrefix % (symbol)
		notes = notePrefix % (r['geneID'])

		mgcFile.write(markerType + TAB + \
			      symbol + TAB + \
			      name + TAB + \
			      chromosome + TAB + \
			      markerStatus + TAB + \
			      reference + TAB + \
			      TAB + \
			      accidstr + TAB + \
			      notes + TAB + \
			      submitter + CRT)

#
# Main
#

init()
process()
exit(0)

