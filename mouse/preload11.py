#!/usr/local/bin/python

'''
#
# preload11.py 10/05/2000
#
# Report:
#       EntrezGene Mouse Symbols w/ Published GenBank IDs (in EntrezGene) which do not exist in MGI
#	and the Publication exists in MGI (by PubMed UI)
#
# Usage:
#       preload11.py
#
# Used by:
#	Curatorial Group
#
# Notes:
#
# History:
#
# lec 09/12/2003
#	- TR 4342; remove singletons; this was later reversed
#	- print out ALL references associated with the EntrezGene ID
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
logicalSeqKey = os.environ['LOGICALSEQKEY']
markerTypeKey = os.environ['MARKERTYPEKEY']

fp = reportlib.init(sys.argv[0], 'Bucket 11 - EntrezGene Mouse Symbols w/ Published GenBank ID; GenBank ID Not Attached to MGI Marker; Reference in MGI', outputdir = os.environ['MOUSEDATADIR'])

fp.write('''EntrezGene records w/ published non-genomic Seq ID where: 
	  1.  None of the EntrezGene Seq IDs is attached to an MGI Marker.
	  OR
	  2.  One or more of its Seq IDs is attached to an MGI Probe but not an MGI Marker. 

     An EntrezGene record is determined to be published if it has at least one PubMed ID.
     A reference is determined to be in MGI if the EntrezGene PubMed ID is in MGI.
     Seq IDs which are attached to MGI Probes contain an asterisk.

''')

fp.write(string.ljust('EntrezGene ID', 10) + SPACE)
fp.write(string.ljust('EntrezGene Symbol', 20) + SPACE)
fp.write(string.ljust('MGI Acc ID', 20) + SPACE)
fp.write(string.ljust('J#', 50) + SPACE)
fp.write(string.ljust('GenBank ID', 11) + CRT)

fp.write(string.ljust('-----', 10) + SPACE)
fp.write(string.ljust('---------', 20) + SPACE)
fp.write(string.ljust('----------', 20) + SPACE)
fp.write(string.ljust('-----', 50) + SPACE)
fp.write(string.ljust('-----------', 11) + CRT)

cmds = []

# select all entrez gene ids which contain non-genomic genbank ids 
# for which a match to a MGI Marker is found

cmds.append('select distinct l.geneID ' + \
'into #matchFound ' + \
'from %s..DP_LLAcc l, ACC_Accession a ' % (radar) + \
'where a._MGIType_key = %s ' % (markerTypeKey) + \
'and a._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and a.accID = l.genbankID ' + \
'and l.seqType != "g" ' + \
'and not exists (select 1 from %s..WRK_LLExcludeNonGenes e ' % (radar) + \
'where l.geneID = e.geneID)')
 
cmds.append('create nonclustered index index_geneID on #matchFound(geneID)')

# select published...
#
# select all entrez gene records for which none of its genbank ids can be found attached
# to an MGI Marker
# plus
# select all entrez gene records for which a genbank id can be found attached
# to an MGI Probe but not an MGI Marker

cmds.append('select l.geneID, l.symbol, l.locusTag, a.genbankID, category = "M" ' + \
'into #ll1 ' + \
'from %s..DP_EntrezGene_Info l, %s..DP_LLAcc a ' % (radar, radar) + \
'where l.taxid = %s ' % (taxID) + \
'and l.geneID = a.geneID ' + \
'and a.genbankID not like "NM%" ' + \
'and a.seqType != "g" ' + \
'and not exists (select 1 from #matchFound m ' + \
'where l.geneID = m.geneID) ' + \
'and not exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = %s ' % (markerTypeKey) + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID) ' + \
'and exists (select 1 from %s..DP_EntrezGene_PubMed c ' % (radar) + \
'where l.geneID = c.geneID) ')

cmds.append('select l.geneID, l.symbol, l.locusTag, a.genbankID, category = "P" ' + \
'into #ll2 ' + \
'from %s..DP_EntrezGene_Info l, %s..DP_LLAcc a ' % (radar, radar) + \
'where l.taxid = %s ' % (taxID) + \
'and l.geneID = a.geneID ' + \
'and a.genbankID not like "NM%" ' + \
'and a.seqType != "g" ' + \
'and not exists (select 1 from #matchFound m ' + \
'where l.geneID = m.geneID) ' + \
'and not exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = %s ' % (markerTypeKey) + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID) ' + \
'and exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = 3 ' + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID) ' + \
'and exists (select 1 from %s..DP_EntrezGene_PubMed c ' % (radar) + \
'where l.geneID = c.geneID)')

cmds.append('select * into #ll3 from #ll1 union select * from #ll2')

cmds.append('create nonclustered index index_geneID on #ll3(geneID)')

# select records where the reference is in MGI

cmds.append('select l.* ' + \
'into #ll4 ' + \
'from #ll3 l ' + \
'where exists (select 1 from %s..DP_EntrezGene_PubMed c, ACC_Accession a1 ' % (radar) + \
'where l.geneID = c.geneID ' + \
'and c.pubmedID = a1.accID ' + \
'and a1._MGIType_key = 1)')

cmds.append('create nonclustered index index_geneID on #ll4(geneID)')

cmds.append('select l.*, jnumID = a2.accID, a2.prefixPart ' + \
'into #ll5 ' + \
'from #ll4 l, %s..DP_EntrezGene_PubMed c, ACC_Accession a1, ACC_Accession a2 ' % (radar) + \
'where l.geneID = c.geneID ' + \
'and c.pubmedID = a1.accID ' + \
'and a1._MGIType_key = 1 ' + \
'and a1._Object_key = a2._Object_key ' + \
'and a2._MGIType_key = 1 ')

# select final records

cmds.append('select * into #final from #ll5 where prefixPart = "J:"')

cmds.append('create nonclustered index index_geneID on #final(geneID)')

cmds.append('select distinct geneID, jnumID from #final order by geneID, jnumID')

cmds.append('select distinct geneID, genbankID, category from #final order by geneID, genbankID, category desc')

cmds.append('select distinct geneID, symbol, locusTag from #final order by geneID')

results = db.sql(cmds, 'auto')
sys.exit(0)

refs = {}
for r in results[-3]:
    key = r['geneID']
    value = r['jnumID']
    if not refs.has_key(key):
	refs[key] = []
    refs[key].append(value)
    
seqs = {}
for r in results[-2]:
    key = r['geneID']
    value = r['genbankID']

    if not seqs.has_key(key):
	seqs[key] = []

    if r['category'] == 'P':
	value = value + '*'

    if r['genbankID'] not in seqs[key] and r['genbankID'] + '*' not in seqs[key]:
        seqs[key].append(value)

rows = 0
for r in results[-1]:

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
reportlib.finish_nonps(fp)

