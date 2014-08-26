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
import re

TAB = '\t'
CRT = '\n'

#
# Main
#

inputDir = os.environ['EGINPUTDIR']

infoFile = open(inputDir + '/gene_info.mgi', 'r')
infoOutFile = open(inputDir + '/gene_info.bcp', 'w')
synOutFile = open(inputDir + '/gene_synonym.bcp', 'w')
dbxOutFile = open(inputDir + '/gene_dbxref.bcp', 'w')

for line in infoFile.readlines():

	tokens = string.splitfields(line[:-1], TAB)

	taxID = tokens[0]
	geneID = tokens[1]
	symbol = tokens[2]
	locusTag = tokens[3]
	synonyms = tokens[4]
	dbxRefs = tokens[5]
	chr = tokens[6]
	mp = tokens[7]
	name = tokens[8]
	geneType = tokens[9]
	symbol2 = tokens[10]
	name2 = tokens[11]
	status = tokens[12]

	# if status = "O", then symbol = symbol, name = name
	# if status = "I", then symbol = symbol2, name = name2

	if status == 'I':
	    symbol = symbol2
	    name = name2

	infoOutFile.write(taxID + TAB + status + TAB + geneID + TAB + \
		symbol + TAB + locusTag + TAB + chr + TAB + mp + TAB + name[:255] + TAB + geneType[:255] + CRT)

	for s in string.split(synonyms, '|'):
		if s != '-':
			synOutFile.write(taxID + TAB + geneID + TAB + s + CRT)

	for s in string.split(dbxRefs, '|'):
		if s != '-':
			#
			# Remove prefixing for MGI and HGNC IDs (TR11734).
			#
			s = s.replace('MGI:MGI:','MGI:')
			s = s.replace('HGNC:HGNC:','HGNC:')
			dbxOutFile.write(taxID + TAB + geneID + TAB + s + CRT)

infoFile.close()
infoOutFile.close()
synOutFile.close()
dbxOutFile.close()


