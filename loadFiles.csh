#!/bin/csh -fx

#
# Loads EntrezGene files into ${RADARDB}
#
# Usage:  loadFiles.sh
#

cd `dirname $0` && source ./Configuration

cd ${EGDATADIR}

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

# grab latest files

#cp ${FTPDATA1}/gene2accession.gz ${EGINPUTDIR}
#cp ${FTPDATA1}/gene2pubmed.gz ${EGINPUTDIR}
#cp ${FTPDATA1}/gene2refseq.gz ${EGINPUTDIR}
#cp ${FTPDATA1}/gene_info.gz ${EGINPUTDIR}

# uncompress the files
#cd ${EGINPUTDIR}
#foreach i (*.gz)
#/usr/local/bin/gunzip -f $i >>& ${LOG}
#end

# split up gene_info
cd ${EGINSTALLDIR}
./geneinfo.py >>& ${LOG}

# strip version numbers out of gene2accession, gene2refseq
./stripversion.py >>& ${LOG}

# truncate existing tables
${RADARDBSCHEMADIR}/table/DP_EntrezGene_truncate.logical >>& ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/DP_EntrezGene_drop.logical >>& ${LOG}

# bcp new data into tables
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Accession in ${EGINPUTDIR}/gene2accession.new -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Info in ${EGINPUTDIR}/gene_info.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_DBXRef in ${EGINPUTDIR}/gene_dbxref.bcp -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_PubMed in ${EGINPUTDIR}/gene2pubmed -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_RefSeq in ${EGINPUTDIR}/gene2refseq.new -c -t\\t -U${DBUSER} >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${RADARDB}..DP_EntrezGene_Synonym in ${EGINPUTDIR}/gene_synonym.bcp -c -t\\t -U${DBUSER} >>& ${LOG}

# create indexes
${RADARDBSCHEMADIR}/index/DP_EntrezGene_create.logical >>& ${LOG}

date >> ${LOG}
