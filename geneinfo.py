#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Convert gene_info into gene_info_synonyms, gene_info_dbXrefs
#	for loading into:
#
#	DP_EntrezGene_Info
#	DP_EntrezGene_Synonym
#	DP_EntrezGene_DBXRef
#  
# Input:
#
#	gene_info
#
# Assumes:
#
# Output:
#
#	gene_info.bcp
#	gene_synonym.bcp
#	gene_dbxref.bcp
#
# Processing:
#
# History:
#
# lec	07/07/2004
#	- created
#
'''

import sys
import os
import string
import regsub

TAB = '\t'
CRT = '\n'

#
# Main
#

inputDir = os.environ['EGINPUTDIR']

infoFile = open(inputDir + '/gene_info', 'r')
infoOutFile = open(inputDir + '/gene_info.bcp', 'w')
synOutFile = open(inputDir + '/gene_synonym.bcp', 'w')
dbxOutFile = open(inputDir + '/gene_dbxref.bcp', 'w')

for line in infoFile.readlines():
	[taxID, geneID, symbol, locusTag, synonyms, dbxRefs, chr, mp, name, geneType] = string.splitfields(line[:-1], TAB)

	infoOutFile.write(taxID + TAB + geneID + TAB + symbol + TAB + locusTag + TAB + chr + TAB + mp + TAB + name[:255] + TAB + geneType[:255] + CRT)

	for s in string.split(synonyms, '|'):
		if s != '-':
			synOutFile.write(geneID + TAB + s + CRT)

	for s in string.split(dbxRefs, '|'):
		if s != '-':
			dbxOutFile.write(geneID + TAB + s + CRT)

infoFile.close()
infoOutFile.close()
synOutFile.close()
dbxOutFile.close()


