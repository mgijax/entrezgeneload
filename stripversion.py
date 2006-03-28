#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Convert accession.version in gene2accession to accession
#	Convert accession.version in gene2refseq to accession
#  
# Input:
#
#	gene2accession
#	gene2refseq
#
# Assumes:
#
# Output:
#
#	gene2accession.new
#	gene2refseq.new
#
# Processing:
#
# History:
#
# lec	7/7/2004
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
# pulled from mass/dev/lib/python/mass.py
#

def splitSeqIdV(seqIdVersion):      # String - seqId.version

        # Purpose: split 'seqIdVersion' into seqId and version
        # Returns: list of two strings - 1) seqId 2) version 
        # Assumes: nothing
        # Effects: nothing
        # Throws: nothing
        # Example1: seqId, version = splitSeqIdV('AC002397.1')
        #           seqId = 'AC002397'
        #           version = '1'
        # Example2: seqId, version = splitSeqIdV('AC002397')
        #           seqId = 'AC002397'
        #           version = ''

        index = string.find(seqIdVersion, '.')
        if index == -1:
                return [seqIdVersion, '']
        else:
                seqId = seqIdVersion[0:index]
                version = seqIdVersion[index+1:]
                return [seqId, version]

#
# Main
#

inputDir = os.environ['EGINPUTDIR']

accFile = open(inputDir + '/gene2accession.mgi', 'r')
newaccFile = open(inputDir + '/gene2accession.new', 'w')

for line in accFile.readlines():
	[taxID, geneID, status, rna, rnaGI, protein, proteinGI, genomic, genomicGI, startPos, endPos, orient, assembly] = string.splitfields(line[:-1], TAB)
	[newRNA, version] = splitSeqIdV(rna)
	[newProtein, version] = splitSeqIdV(protein)
	[newGenomic, version] = splitSeqIdV(genomic)
	newaccFile.write(taxID + TAB + \
			 geneID + TAB + \
			 status + TAB + \
			 newRNA + TAB + \
			 rnaGI + TAB + \
			 newProtein + TAB + \
			 proteinGI + TAB + \
			 newGenomic + TAB + \
			 genomicGI + TAB + \
			 startPos + TAB + \
			 endPos + TAB + \
			 orient + CRT)
accFile.close()
newaccFile.close()

refFile = open(inputDir + '/gene2refseq.mgi', 'r')
newrefFile = open(inputDir + '/gene2refseq.new', 'w')

for line in refFile.readlines():
	[taxID, geneID, status, rna, rnaGI, protein, proteinGI, genomic, genomicGI, startPos, endPos, orient, assembly] = string.splitfields(line[:-1], TAB)
	[newRNA, version] = splitSeqIdV(rna)
	[newProtein, version] = splitSeqIdV(protein)
	[newGenomic, version] = splitSeqIdV(genomic)
	newrefFile.write(taxID + TAB + \
			 geneID + TAB + \
			 status + TAB + \
			 newRNA + TAB + \
			 rnaGI + TAB + \
			 newProtein + TAB + \
			 proteinGI + TAB + \
			 newGenomic + TAB + \
			 genomicGI + TAB + \
			 startPos + TAB + \
			 endPos + TAB + \
			 orient + CRT)
refFile.close()
newrefFile.close()

