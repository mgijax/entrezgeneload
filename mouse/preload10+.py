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
taxID = os.environ['MOUSETAXID']
markerTypeKey = os.environ['MARKERTYPEKEY']
probeTypeKey = os.environ['PROBETYPEKEY']
logicalSeqKey = os.environ['LOGICALSEQKEY']
rows = 0

def printRecord(fp, r, sequence, refs, nomen):
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

			if refs.has_key(s):
				fp.write(string.ljust(refs[s], 10) + SPACE)

			if nomen.has_key(s):
				[accID, status, symbol] = string.split(nomen[s], ';')
				fp.write(string.ljust(status, 15) + SPACE)
				fp.write(string.ljust(accID, 20) + SPACE)
				fp.write(string.ljust(symbol, 50) + SPACE)
			fp.write(CRT)

	rows = rows + 1
# end printRecord

def createMatches():

    #
    # select all EntrezGene records with a rna genbank id associated with a MGI Marker
    #

    db.sql('select distinct e.geneID ' + \
	'into #markermatch ' + \
	'from %s..DP_EntrezGene_Accession e, ACC_Accession a ' % (radar) + \
	'where a._MGIType_key = %s ' % (markerTypeKey) + \
	'and a._LogicalDB_key = %s ' % (logicalSeqKey) + \
	'and a.accID = e.rna ', None)
    db.sql('create index idx1 on #markermatch(geneID)', None)

    #
    # select all EntrezGene records with a rna genbank id associated with a MGI Probe
    #

    db.sql('select distinct e.geneID ' + \
	'into #probematch ' + \
	'from %s..DP_EntrezGene_Accession e, ACC_Accession a ' % (radar) + \
	'where a._MGIType_key = %s ' % (probeTypeKey) + \
	'and a._LogicalDB_key = %s ' % (logicalSeqKey) + \
	'and a.accID = e.rna ', None)
    db.sql('create index idx1 on #probematch(geneID)', None)

def bucket10(fp):

    global rows

    fp.write('''EntrezGene records w/ unpublished non-genomic Seq ID where: 
	      1.  None of the EntrezGene Seq IDs is attached to an MGI Marker or an MGI Probe.

         An EntrezGene record is determined to be unpublished it has no PubMed ID. 
         Excludes genomic Seq IDs.
    ''')

    fp.write(CRT)
    fp.write(string.ljust('EG ID', 10) + SPACE)
    fp.write(string.ljust('EG Symbol', 35) + SPACE)
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

    # select all EntrezGene records for which none of its rna ids can be found associated with a Marker or Probe
    # and that is unpublished

    db.sql('select distinct e.geneID, e.rna ' + \
	'into #bucket10 ' + \
	'from %s..DP_EntrezGene_Accession e ' % (radar) + \
	'where e.taxid = %s ' % (taxID) + \
	'and e.rna != "-" ' + \
	'and e.rna not like "N%_%" ' + \
	'and e.rna not like "X%_%" ' + \
	'and not exists (select 1 from #markermatch m where e.geneID = m.geneID) ' + \
	'and not exists (select 1 from #probematch m where e.geneID = m.geneID) ' + \
	'and not exists (select 1 from %s..DP_EntrezGene_PubMed c where e.geneID = c.geneID)' % (radar), None)
    db.sql('create index idx1 on #bucket10(geneID)', None)
    db.sql('create index idx2 on #bucket10(rna)', None)

    #
    # retrieve rna/jnum pairs
    #

    refs = {}

    # from BIB_Refs.pgs
    results = db.sql('select b.rna, a.accID ' + \
	    'from #bucket10 b, BIB_Refs r, BIB_Acc_View a ' + \
	    'where b.rna = r.pgs ' + \
	    'and r._Refs_key = a._Object_key ' + \
	    'and a._LogicalDB_key = 1 ' + \
	    'and a.prefixPart = "J:" ' + \
	    'and a.preferred = 1', 'auto')
    for r in results:
	key = r['rna']
	value = r['accID']
	refs[key] = value

    # from BIB_Notes
    results = db.sql('select genbankIDs = ltrim(rtrim(substring(n.note, 10, 255))), a.accID ' + \
	    'from BIB_Notes n, BIB_Acc_View a ' + \
	    'where n.note like "genbank%" ' + \
	    'and n._Refs_key = a._Object_key ' + \
	    'and a.prefixPart = "J:" ' + \
	    'and a._LogicalDB_key = 1 ' + \
	    'and a.preferred = 1', 'auto')
    for r in results:
	key = r['genbankIDs']
	value = r['accID']
	for s in string.split(key, ','):
		if not refs.has_key(s):
			refs[s] = value

    # from NomenDB
    results = db.sql('select distinct b.rna, a.jnumID ' + \
	    'from #bucket10 b, NOM_AccRef_View a ' + \
	    'where b.rna = a.accID', 'auto')
    for r in results:
	    key = r['rna']
	    value = r['jnumID']
	    if not refs.has_key(key):
		    refs[key] = value

    #
    # Nomenclature information
    #

    results = db.sql('select distinct b.rna, a2.accID, n.status, n.symbol ' + \
	'from #bucket10 b, ACC_Accession a1, ACC_Accession a2, NOM_Marker_View n ' + \
	'where b.rna = a1.accID ' + \
	'and a1._MGIType_key = 21 ' + \
	'and a1._Object_key = a2._Object_key ' + \
	'and a2._MGIType_key = 21 ' + \
	'and a2._LogicalDB_key = 1 ' + \
	'and a2.prefixPart = "MGI:" ' + \
	'and a2.preferred = 1 ' + \
	'and a2._Object_key = n._Nomen_key ', 'auto')
    nomen = {}
    for r in results:
	key = r['rna']
	value = r['accID'] + ';' + r['status'] + ';' + r['symbol']
	if not nomen.has_key(key):
		nomen[key] = value

    #
    # Gene/Sequence data
    #

    results = db.sql('select geneID, rna from #bucket10', 'auto')
    sequence = {}
    for r in results:
	key = r['geneID']
	value = r['rna']
	if not sequence.has_key(key):
		sequence[key] = []
	sequence[key].append(value)

    #
    # Process data
    #

    results = db.sql('select distinct b.geneID, i.symbol, i.locusTag ' + \
	    'from #bucket10 b, %s..DP_EntrezGene_Info i ' % (radar) + \
	    'where b.geneID = i.geneID', 'auto')

    rows = 0

    # print out EntrezGene ids that have Sequences that don't have any J#s
    for r in results:
	printIt = 1
	for s in sequence[r['geneID']]:
		if refs.has_key(s):
			printIt = 0
	if printIt:
		printRecord(fp, r, sequence, refs, nomen)

    # print out EntrezGene ids which have Sequences which have J#s and no Nomen status
    for r in results:
	printIt = 0
	for s in sequence[r['geneID']]:
		if refs.has_key(s) and not nomen.has_key(s):
			printIt = 1
	if printIt:
		printRecord(fp, r, sequence, refs, nomen)

    # print out EntrezGene ids which have Sequences which have J#s and a Nomen status
    for nstatus in ['Reserved', 'In Progress', 'Unreviewed', 'Deleted', 'Approved', 'Broadcast - Official', 'Broadcast - Interim']:
	for r in results:
		printIt = 0
		for s in sequence[r['geneID']]:
			if refs.has_key(s) and nomen.has_key(s):
				[accID, status, symbol] = string.split(nomen[s], ';')
				if status == nstatus:
					printIt = 1
		if printIt:
			printRecord(fp, r, sequence, refs, nomen)


    fp.write(2*CRT + '(%d EntrezGene records)' % (rows) + CRT)

    reportlib.trailer(fp)

def bucket11(fp):

    global rows

    fp.write('''EntrezGene records w/ published non-genomic Seq ID where: 
	      1.  None of the EntrezGene Seq IDs is attached to an MGI Marker.
	      OR
	      2.  One or more of its Seq IDs is attached to an MGI Probe but not an MGI Marker. 

         An EntrezGene record is determined to be published if it has at least one PubMed ID.
         A reference is determined to be in MGI if the EntrezGene PubMed ID is in MGI.
         Seq IDs which are attached to MGI Probes contain an asterisk.
    ''')

    fp.write(CRT)
    fp.write(string.ljust('EG ID', 10) + SPACE)
    fp.write(string.ljust('EG Symbol', 20) + SPACE)
    fp.write(string.ljust('MGI Acc ID', 20) + SPACE)
    fp.write(string.ljust('J#', 50) + SPACE)
    fp.write(string.ljust('GenBank ID', 11) + CRT)

    fp.write(string.ljust('-----', 10) + SPACE)
    fp.write(string.ljust('---------', 20) + SPACE)
    fp.write(string.ljust('----------', 20) + SPACE)
    fp.write(string.ljust('-----', 50) + SPACE)
    fp.write(string.ljust('-----------', 11) + CRT)

    #
    # select all published EntrezGene records 
    # for which none of its genbank ids can be found attached to a MGI Marker
    #

    db.sql('select distinct e.geneID, e.rna, category = "M" ' + \
            'into #bucket11 ' + \
            'from %s..DP_EntrezGene_Accession e ' % (radar) + \
            'where e.taxid = %s ' % (taxID) + \
            'and e.rna != "-" ' + \
            'and e.rna not like "N%_%" ' + \
            'and e.rna not like "X%_%" ' + \
            'and not exists (select 1 from #markermatch m where e.geneID = m.geneID) ' + \
            'and exists (select 1 from %s..DP_EntrezGene_PubMed c where e.geneID = c.geneID)' % (radar), None)

    #
    # select all published EntrezGene records 
    # for which at least one of its genbank ids can be found attached to a MGI Probe
    # but not a MGI Marker

    db.sql('insert into #bucket11 ' + \
	    'select distinct e.geneID, e.rna, category = "P" ' + \
            'from %s..DP_EntrezGene_Accession e ' % (radar) + \
            'where e.taxid = %s ' % (taxID) + \
            'and e.rna != "-" ' + \
            'and e.rna not like "N%_%" ' + \
            'and e.rna not like "X%_%" ' + \
            'and exists (select 1 from #probematch m where e.geneID = m.geneID) ' + \
            'and not exists (select 1 from #markermatch m where e.geneID = m.geneID) ' + \
            'and exists (select 1 from %s..DP_EntrezGene_PubMed c where e.geneID = c.geneID)' % (radar), None)
    db.sql('create index idx1 on #bucket11(geneID)', None)
    db.sql('create index idx2 on #bucket11(rna)', None)

    #
    # select references
    #

    results = db.sql('select b.geneID, c.pubMedID, a._Object_key ' + \
	    'into #bucket11refs ' + \
	    'from #bucket11 b, %s..DP_EntrezGene_PubMed c, ACC_Accession a ' % (radar) + \
	    'where b.geneID = c.geneID ' + \
	    'and c.pubMedID = a.accID ' + \
	    'and a._MGIType_key = 1', 'auto')
    db.sql('create index idx1 on #bucket11refs(_Object_key)', None)

    results = db.sql('select distinct r.geneID, a.accID ' + \
	'from #bucket11refs r, ACC_Accession a ' + \
	'where r._Object_key = a._Object_key ' + \
	'and a._MGIType_key = 1 ' + \
	'and a.prefixPart = "J:"', 'auto')
    refs = {}
    for r in results:
        key = r['geneID']
        value = r['accID']
        if not refs.has_key(key):
	    refs[key] = []
        refs[key].append(value)
    
    #
    # select sequences
    #

    results = db.sql('select distinct geneID, rna, category from #bucket11 b ' + \
	'where exists (select 1 from #bucket11refs r where b.geneID = r.geneID) ' + \
	'order by geneID, rna, category desc', 'auto')
    seqs = {}
    for r in results:
        key = r['geneID']
        value = r['rna']
        pvalue = r['rna'] + '*'
    
        if not seqs.has_key(key):
	    seqs[key] = []

        if r['category'] == 'P':
	    value = pvalue

        if value not in seqs[key]:
            seqs[key].append(value)

    #
    # final results
    #

    rows = 0

    results = db.sql('select distinct b.geneID, i.symbol, i.locusTag ' + \
	    'from #bucket11 b, %s..DP_EntrezGene_Info i ' % (radar) + \
	    'where exists (select 1 from #bucket11refs r where b.geneID = r.geneID) ' + \
	    'and b.geneID = i.geneID ' + \
	    'order by b.geneID', 'auto')

    for r in results:
	fp.write(string.ljust(r['geneID'], 10) + SPACE)
	fp.write(string.ljust(r['symbol'], 20) + SPACE)
	fp.write(string.ljust(mgi_utils.prvalue(r['locusTag']), 20) + SPACE)

	refString = string.joinfields(refs[r['geneID']], ',')
	if len(refString) > 50:
	    fp.write(string.ljust(refString[:50], 50) + SPACE)
	    fp.write(string.ljust(string.joinfields(seqs[r['geneID']], ','), 50))
	    fp.write(CRT)
	    fp.write(53*SPACE + refString[50:] + CRT)
	else:
	    fp.write(string.ljust(refString, 50) + SPACE)
	    fp.write(string.ljust(string.joinfields(seqs[r['geneID']], ','), 50))
	    fp.write(CRT)

	rows = rows + 1

    fp.write(2*CRT + '(%d rows affected)' % (rows) + CRT)

    reportlib.trailer(fp)

def bucket12(fp):

    global rows

    fp.write('''EntrezGene records w/ published Seq ID where: 
	      1.  None of the EntrezGene Seq IDs is attached to an MGI Marker.
	      OR
	      2.  One or more of its Seq IDs is attached to an MGI Probe but not an MGI Marker. 

         An EntrezGene record is determined to be published if it has at least one PubMed ID.
         A reference is determined to not be in MGI if the EntrezGene PubMed ID is not in MGI.
         Seq IDs which are attached to MGI Probes contain an asterisk.
    ''')

    fp.write(CRT)
    fp.write(string.ljust('EG ID', 10) + SPACE)
    fp.write(string.ljust('EG Symbol', 20) + SPACE)
    fp.write(string.ljust('MGI Acc ID', 20) + SPACE)
    fp.write(string.ljust('PubMed ID', 20) + SPACE)
    fp.write(string.ljust('GenBank ID', 11) + CRT)

    fp.write(string.ljust('-----', 10) + SPACE)
    fp.write(string.ljust('---------', 20) + SPACE)
    fp.write(string.ljust('----------', 20) + SPACE)
    fp.write(string.ljust('-----------', 20) + SPACE)
    fp.write(string.ljust('-----------', 11) + CRT)

    #
    # create bucket 12 from bucket 11; this time we're interested in those records
    # that don't have a reference in MGI
    #

    db.sql('select distinct b.geneID, b.rna, b.category ' + \
	'into #bucket12 ' + \
	'from #bucket11 b ' + \
	'where not exists (select 1 from #bucket11refs r where b.geneID = r.geneID)', None)
    db.sql('create index idx1 on #bucket12(geneID)', None)

    results = db.sql('select b.geneID, c.pubMedID ' + \
	    'from #bucket12 b, %s..DP_EntrezGene_PubMed c ' % (radar) + \
	    'where b.geneID = c.geneID ', 'auto')
    refs = {}
    for r in results:
        key = r['geneID']
        value = r['pubMedID']
        if not refs.has_key(key):
	    refs[key] = []
        refs[key].append(value)

    #
    # select sequences
    #

    results = db.sql('select geneID, rna, category from #bucket12 order by geneID, rna, category desc', 'auto')

    seqs = {}
    for r in results:
        key = r['geneID']
        value = r['rna']
        pvalue = r['rna'] + '*'

        if not seqs.has_key(key):
	    seqs[key] = []

        if r['category'] == 'P':
	    value = pvalue

        if value not in seqs[key]:
            seqs[key].append(value)

    rows = 0

    results = db.sql('select distinct b.geneID, i.symbol, i.locusTag ' + \
	    'from #bucket12 b, %s..DP_EntrezGene_Info i ' % (radar) + \
	    'where b.geneID = i.geneID ' + \
	    'order by b.geneID', 'auto')

    for r in results:

	fp.write(string.ljust(r['geneID'], 10) + SPACE)
	fp.write(string.ljust(r['symbol'], 20) + SPACE)
	fp.write(string.ljust(mgi_utils.prvalue(r['locusTag']), 20) + SPACE)

	refString = string.joinfields(refs[r['geneID']], ',')
	if len(refString) > 50:
	    fp.write(string.ljust(refString[:50], 50) + SPACE)
	    fp.write(string.ljust(string.joinfields(seqs[r['geneID']], ','), 50))
	    fp.write(CRT)
	    fp.write(53*SPACE + refString[50:] + CRT)
	else:
	    fp.write(string.ljust(refString, 20) + SPACE)
	    fp.write(string.ljust(string.joinfields(seqs[r['geneID']], ','), 50))
	    fp.write(CRT)

	rows = rows + 1

    fp.write(2*CRT + '(%d rows affected)' % (rows) + CRT)

    reportlib.trailer(fp)

def openFiles():

    title = 'Bucket 10 - EntrezGene Mouse Symbols w/ Unpublished GenBank ID; GenBank ID Not Attached to MGI Marker'
    fp10 = reportlib.init('preload10', title, outputdir = os.environ['MOUSEDATADIR'])

    title = 'Bucket 11 - EntrezGene Mouse Symbols w/ Published GenBank ID; GenBank ID Not Attached to MGI Marker; Reference in MGI'
    fp11 = reportlib.init('preload11', title, outputdir = os.environ['MOUSEDATADIR'])

    title = 'Bucket 12 - EntrezGene Mouse Symbols w/ Published GenBank ID; GenBank ID Not Attached to MGI Marker; Reference not in MGI'
    fp12 = reportlib.init('preload12', title, outputdir = os.environ['MOUSEDATADIR'])

    return fp10, fp11, fp12

def closeFiles(fp10, fp11, fp12):

    reportlib.finish_nonps(fp10)
    reportlib.finish_nonps(fp11)
    reportlib.finish_nonps(fp12)

#
# Main
#

fp10, fp11, fp12 = openFiles()
createMatches()
bucket10(fp10)
bucket11(fp11)
bucket12(fp12)
closeFiles(fp10, fp11, fp12)

