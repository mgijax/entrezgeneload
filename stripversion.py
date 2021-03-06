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
# sc    03/8/2010
#	- added 'assembly' column
# lec	7/7/2004
#	- created
#
'''

import sys
import os

TAB = '\t'
CRT = '\n'

#
# pulled from mass/dev/lib/python/mass.py
#

def splitSeqIdV(seqIdVersion):      # String - seqId.version

        # Purpose: split 'seqIdVersion' into seqId and version
        # Returns: list of two string - 1) seqId 2) version 
        # Assumes: nothing
        # Effects: nothing
        # Throws: nothing
        # Example1: seqId, version = splitSeqIdV('AC002397.1')
        #           seqId = 'AC002397'
        #           version = '1'
        # Example2: seqId, version = splitSeqIdV('AC002397')
        #           seqId = 'AC002397'
        #           version = ''

        index = str.find(seqIdVersion, '.')
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
        tokens = str.split(line[:-1], TAB)
        taxID = tokens[0]
        geneID = tokens[1]
        status = tokens[2]
        rna = tokens[3]
        rnaGI = tokens[4]
        protein = tokens[5]
        proteinGI = tokens[6]
        genomic = tokens[7]
        genomicGI = tokens[8]
        startPos = tokens[9]
        endPos = tokens[10]
        orient = tokens[11]
        assembly = tokens[12]
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
                         orient + TAB + \
                         assembly + CRT)
accFile.close()
newaccFile.close()

refFile = open(inputDir + '/gene2refseq.mgi', 'r')
newrefFile = open(inputDir + '/gene2refseq.new', 'w')

for line in refFile.readlines():
        tokens = str.split(line[:-1], TAB)
        taxID = tokens[0]
        geneID = tokens[1]
        status = tokens[2]
        rna = tokens[3]
        rnaGI = tokens[4]
        protein = tokens[5]
        proteinGI = tokens[6]
        genomic = tokens[7]
        genomicGI = tokens[8]
        startPos = tokens[9]
        endPos = tokens[10]
        orient = tokens[11]
        assembly = tokens[12]
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
