#!/usr/local/bin/python

'''
#
# preload12.py 10/05/2000
#
# Report:
#       EntrezGene Mouse Symbols w/ Published GenBank IDs (in EntrezGene) which do not exist in MGI
#	and the Publication does not exist in MGI (by PubMed ID)
#
# Usage:
#       preload12.py
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
logicalSeqKey = os.environ['LOGICALSEQKEY']
markerTypeKey = os.environ['MARKERTYPEKEY']

fp = reportlib.init(sys.argv[0], 'Bucket 12 - EntrezGene Mouse Symbols w/ Published GenBank ID; GenBank ID Not Attached to MGI Marker; Reference not in MGI', outputdir = os.environ['MOUSEDATADIR'])

fp.write('''EntrezGene records w/ published Seq ID where: 
	  1.  None of the EntrezGene Seq IDs is attached to an MGI Marker.
	  OR
	  2.  One or more of its Seq IDs is attached to an MGI Probe but not an MGI Marker. 

     An EntrezGene record is determined to be published if it has at least one PubMed ID.
     A reference is determined to not be in MGI if the EntrezGene PubMed ID is not in MGI.
     Seq IDs which are attached to MGI Probes contain an asterisk.

''')

fp.write(string.ljust('EntrezGene ID', 10) + SPACE)
fp.write(string.ljust('EntrezGene Symbol', 20) + SPACE)
fp.write(string.ljust('MGI Acc ID', 20) + SPACE)
fp.write(string.ljust('PubMed ID', 20) + SPACE)
fp.write(string.ljust('GenBank ID', 11) + CRT)

fp.write(string.ljust('-----', 10) + SPACE)
fp.write(string.ljust('---------', 20) + SPACE)
fp.write(string.ljust('----------', 20) + SPACE)
fp.write(string.ljust('-----------', 20) + SPACE)
fp.write(string.ljust('-----------', 11) + CRT)

cmds = []

# select all entrez gene ids which contain genbank ids for which a match to a 
# MGI Marker is found

cmds.append('select distinct l.geneID ' + \
'into #matchFound ' + \
'from %s..DP_LLAcc l, ACC_Accession a ' % (radar) + \
'where a._MGIType_key = %s ' % (markerTypeKey) + \
'and a._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and a.accID = l.genbankID ' + \
'and not exists (select 1 from %s..WRK_LLExcludeNonGenes e ' % (radar) + \
'where l.geneID = e.geneID)')
 
cmds.append('create nonclustered index index_geneID on #matchFound(geneID)')

# select all entrez gene records for which none of its genbank ids can be found attached
# to an MGI Marker
# plus
# select all entrez gene records for which a genbank id can be found attached
# to an MGI Probe but not an MGI Marker

cmds.append('select l.geneID, l.symbol, l.locusTag, a.genbankID, c.pubMedID, category = "M" ' + \
'into #ll1 ' + \
'from %s..DP_EntrezGene_Info l, %s..DP_LLAcc a, %s..DP_EntrezGene_PubMed c ' % (radar, radar, radar) + \
'where l.taxid = %s ' % (taxID) + \
'and l.geneID = a.geneID ' + \
'and a.genbankID not like "NM%" ' + \
'and l.geneID = c.geneID ' + \
'and not exists (select 1 from #matchFound m ' + \
'where l.geneID = m.geneID) ' + \
'and not exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = %s ' % (markerTypeKey) + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID) ')

cmds.append('select l.geneID, l.symbol, l.locusTag, a.genbankID, c.pubMedID, category = "P" ' + \
'into #ll2 ' + \
'from %s..DP_EntrezGene_Info l, %s..DP_LLAcc a, %s..DP_EntrezGene_PubMed c ' % (radar, radar, radar) + \
'where l.taxid = %s ' % (taxID) + \
'and l.geneID = a.geneID ' + \
'and a.genbankID not like "NM%" ' + \
'and l.geneID = c.geneID ' + \
'and not exists (select 1 from #matchFound m ' + \
'where l.geneID = m.geneID) ' + \
'and not exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = %s ' % (markerTypeKey) + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID) ' + \
'and exists (select 1 from ACC_Accession ma ' + \
'where ma._MGIType_key = 3 ' + \
'and ma._LogicalDB_key = %s ' % (logicalSeqKey) + \
'and ma.accID = a.genbankID)')

cmds.append('select * into #ll3 from #ll1 union select * from #ll2')
cmds.append('create nonclustered index index_geneID on #ll3(geneID)')

# select records where no reference exists in MGI

cmds.append('select distinct l.geneID '+ \
'into #references ' + \
'from #ll3 l, %s..DP_EntrezGene_PubMed c, ACC_Accession a ' % (radar) + \
'where l.geneID = c.geneID ' + \
'and c.pubmedID = a.accID ' + \
'and a._MGIType_key = 1')

cmds.append('create nonclustered index index_geneID on #references(geneID)')

cmds.append('select l.* into #final from #ll3 l ' + \
'where not exists (select 1 from #references r where l.geneID = r.geneID)')

cmds.append('select distinct geneID, pubmedID from #final order by geneID')

cmds.append('select distinct geneID, genbankID, category from #final order by geneID, genbankID, category desc')

cmds.append('select geneID, symbol, locusTag from #final')

results = db.sql(cmds, 'auto')

refs = {}
for r in results[-3]:
    key = r['geneID']
    value = r['pubmedID']
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
	    fp.write(string.ljust(refString, 20) + SPACE)
	    fp.write(string.ljust(string.joinfields(seqs[r['geneID']], ','), 50))
	    fp.write(CRT)

	rows = rows + 1

fp.write(2*CRT + '(%d rows affected)' % (rows) + CRT)

reportlib.trailer(fp)
reportlib.finish_nonps(fp)

