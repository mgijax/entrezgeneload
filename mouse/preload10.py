#!/usr/local/bin/python

'''
#
# preload10.py 10/05/2000
#
# Report:
#       EntrezGene Mouse Symbols w/ Unpublished GenBank IDs (in EntrezGene)
#
# Usage:
#       preload10.py
#
# Used by:
#	Curatorial Group
#
# Notes:
#
# History:
#
# lec 10/05/2000
#	- created
#
'''

import sys
import os
import string
import db
import mgi_utils
import reportlib

SPACE = reportlib.SPACE
TAB = reportlib.TAB
CRT = reportlib.CRT
radar = os.environ['RADARDB']

def printRecord(r):
	global rows

	fp.write(string.ljust(r['geneID'], 10) + SPACE)
	fp.write(string.ljust(r['symbol'], 35) + SPACE)
	fp.write(string.ljust(mgi_utils.prvalue(r['locusTag']), 20) + SPACE)

	# write out each sequence on its own line
	if sequence.has_key(r['geneID']):
		first = 1
		for s in sequence[r['geneID']]:
			if not first:
				fp.write(68*SPACE)

			fp.write(string.ljust(s, 15) + SPACE)
			first = 0

			if genbank.has_key(s):
				fp.write(string.ljust(genbank[s], 10) + SPACE)

			if nomen.has_key(s):
				[accID, status, symbol] = string.split(nomen[s], ';')
				fp.write(string.ljust(status, 15) + SPACE)
				fp.write(string.ljust(accID, 20) + SPACE)
				fp.write(string.ljust(symbol, 50) + SPACE)
			fp.write(CRT)

	rows = rows + 1
# end printRecord

fp = reportlib.init(sys.argv[0], 'Bucket 10 - EntrezGene Mouse Symbols w/ Unpublished GenBank ID; GenBank ID Not Attached to MGI Marker', outputdir = os.environ['MOUSEDATADIR'])

fp.write('''EntrezGene records w/ unpublished non-genomic Seq ID where: 
	  1.  None of the EntrezGene Seq IDs is attached to an MGI Marker or an MGI Probe.

     An EntrezGene record is determined to be unpublished it has no PubMed ID. 
     Excludes genomic Seq IDs.

''')

fp.write(string.ljust('EntrezGene ID', 10) + SPACE)
fp.write(string.ljust('EntrezGene Symbol', 35) + SPACE)
fp.write(string.ljust('MGI Acc ID', 20) + SPACE)
fp.write(string.ljust('GenBank ID', 15) + SPACE)
fp.write(string.ljust('J#', 10) + SPACE)
fp.write(string.ljust('Nomen Status', 15) + SPACE)
fp.write(string.ljust('MGI:', 20) + SPACE)
fp.write(string.ljust('Nomen Symbol', 50) + CRT)

fp.write(string.ljust('-----', 10) + SPACE)
fp.write(string.ljust('---------', 35) + SPACE)
fp.write(string.ljust('----------', 20) + SPACE)
fp.write(string.ljust('-----------', 15) + SPACE)
fp.write(string.ljust('--', 10) + SPACE)
fp.write(string.ljust('------------', 15) + SPACE)
fp.write(string.ljust('----', 25) + SPACE)
fp.write(string.ljust('------------', 50) + CRT)

cmds = []

# list of unique geneids/genbank ids from Bucket 10
cmds.append('select distinct geneID, genbankID = printGB from %s..WRK_LLBucket10' % (radar))

# list of genbank:jnum pairs
cmds.append('select l.genbankID, a.jnumID ' + \
'from BIB_All_View a, %s..WRK_LLBucket10 l ' % (radar) + \
'where l.genbankID = a.pgs')

# list of genbank ids from BIB_Notes
cmds.append('select genbankIDs = ltrim(rtrim(substring(n.note, 10, 255))), a.accID ' + \
'from BIB_Notes n, BIB_Acc_View a ' + \
'where n.note like "genbank%" ' + \
'and n._Refs_key = a._Object_key ' + \
'and a.prefixPart = "J:" ' + \
'and a._LogicalDB_key = 1 ' + \
'and a.preferred = 1')

# list of genbank ids from NomenDB
cmds.append('select distinct l.genbankID, a.jnumID ' + \
'from %s..WRK_LLBucket10 l, NOM_AccRef_View a ' % (radar) + \
'where l.genbankID = a.accID')

# info from NomenDB
cmds.append('select distinct l.genbankID, a2.accID, n.status, n.symbol ' + \
'from %s..WRK_LLBucket10 l, ACC_Accession a1, ' % (radar) + \
'ACC_Accession a2, NOM_Marker_View n ' + \
'where l.genbankID = a1.accID ' + \
'and a1._MGIType_key = 21 ' + \
'and a1._Object_key = a2._Object_key ' + \
'and a2._MGIType_key = 21 ' + \
'and a2._LogicalDB_key = 1 ' + \
'and a2.prefixPart = "MGI:" ' + \
'and a2.preferred = 1 ' + \
'and a2._Object_key = n._Nomen_key ')

# list of distinct geneID
cmds.append('select distinct geneID, symbol, locusTag ' + \
'from %s..WRK_LLBucket10 order by geneID' % (radar))

results = db.sql(cmds, 'auto')

# dictionary of geneID:genbankIDs key:value list
sequence = {}
for r in results[0]:
	key = r['geneID']
	value = r['genbankID']

	if not sequence.has_key(key):
		sequence[key] = []
	sequence[key].append(value)

# dictionary of genbankID:jnum key:value pairs
genbank = {}
for r in results[1]:
	key = r['genbankID']
	value = r['jnumID']
	genbank[key] = value

#  append more data to genbankID:jnum pairs
for r in results[2]:
	key = r['genbankIDs']
	value = r['accID']

	for s in string.split(key, ','):
		if not genbank.has_key(s):
			genbank[s] = value

#  append more data to genbankID:jnum pairs
for r in results[3]:
	key = r['genbankID']
	value = r['jnumID']

	if not genbank.has_key(key):
		genbank[key] = value

# gebankID:nomen info
nomen = {}
for r in results[4]:
	key = r['genbankID']
	value = r['accID'] + ';' + r['status'] + ';' + r['symbol']

	if not nomen.has_key(key):
		nomen[key] = value

rows = 0

# print out EntrezGene ids which have Sequences which don't have any J#s
for r in results[5]:
	printIt = 1
	for s in sequence[r['geneID']]:
		if genbank.has_key(s):
			printIt = 0
	if printIt:
		printRecord(r)

# print out EntrezGene ids which have Sequences which have J#s and no Nomen status
for r in results[5]:
	printIt = 0
	for s in sequence[r['geneID']]:
		if genbank.has_key(s) and not nomen.has_key(s):
			printIt = 1
	if printIt:
		printRecord(r)

# print out EntrezGene ids which have Sequences which have J#s and a Nomen status
for nstatus in ['Reserved', 'In Progress', 'Unreviewed', 'Deleted', 'Approved', 'Broadcast - Official', 'Broadcast - Interim']:
	for r in results[5]:
		printIt = 0
		for s in sequence[r['geneID']]:
			if genbank.has_key(s) and nomen.has_key(s):
				[accID, status, symbol] = string.split(nomen[s], ';')
				if status == nstatus:
					printIt = 1

		if printIt:
			printRecord(r)


fp.write(2*CRT + '(%d LocusLink records)' % (rows) + CRT)

reportlib.trailer(fp)
reportlib.finish_nonps(fp)

