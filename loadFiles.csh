#!/bin/csh -fx

#
# Loads EntrezGene files into ${RADARDB}
#
# Usage:  loadFiles.sh
#

cd `dirname $0` && source ./Configuration

cd ${DATADIR}

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

# grab latest files

#cp ${FTPDATA1}/gene2accession.gz .
#cp ${FTPDATA1}/gene2pubmed.gz .
#cp ${FTPDATA1}/gene2refseq.gz .
#cp ${FTPDATA1}/gene_info.gz .
#cp ${FTPDATA2}/homologene.data .

# uncompress
#foreach i (*.gz)
#/usr/local/bin/gunzip -f $i >>& ${LOG}
#end

# split up gene_info
../geneinfo.py >>& ${LOG}

# strip version numbers out of gene2accession, gene2refseq
../stripversion.py >>& ${LOG}

# truncate existing tables
${RADARDBSCHEMADIR}/table/DP_EntrezGene_truncate.logical >>& ${LOG}
${RADARDBSCHEMADIR}/table/DP_HomoloGene_truncate.object >>& ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/DP_EntrezGene_drop.logical >>& ${LOG}
${RADARDBSCHEMADIR}/index/DP_HomoloGene_drop.object >>& ${LOG}

# bcp new data into tables
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Accession in gene_accession.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Info in gene_info.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_DBXRef in gene_dbxref.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_PubMed in gene2pubmed -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_RefSeq in gene2refseq.new -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Synonym in gene_synonym.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_HomoloGene in homologene.data -c -t\\t -U${DBUSER} >>& ${LOG}

# create indexes
${RADARDBSCHEMADIR}/index/DP_EntrezGene_create.logical >>& ${LOG}
${RADARDBSCHEMADIR}/index/DP_HomoloGene_create.object >>& ${LOG}

date >> ${LOG}
