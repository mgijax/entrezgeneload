#!/bin/csh -fx

#
# Program:
#	loadFiles.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	To copy and load into RADAR the EntrezGene files
#	that were downloaded via mirror_ftp.
#	Also does some minor tweaking of the input.
#
# Requirements Satisfied by This Program:
#
# Usage:
#
# Envvars:
#
# Inputs:
#
# Outputs:
#
# Exit Codes:
#
# Assumes:
#
# Bugs:
#
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

cd `dirname $0` && source ./Configuration

cd ${EGINPUTDIR}

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

# grab latest files

cp ${FTPDATA1}/gene2accession.gz ${EGINPUTDIR}
cp ${FTPDATA1}/gene2pubmed.gz ${EGINPUTDIR}
cp ${FTPDATA1}/gene2refseq.gz ${EGINPUTDIR}
cp ${FTPDATA1}/gene_info.gz ${EGINPUTDIR}
cp ${FTPDATA1}/gene_history.gz ${EGINPUTDIR}
cp ${FTPDATA1}/mim2gene ${EGINPUTDIR}
cp ${FTPDATA2}/homologene.data ${EGINPUTDIR}

# uncompress the files
cd ${EGINPUTDIR}
foreach i (*.gz)
/usr/local/bin/gunzip -f $i >>& ${LOG}
end

# parse out mouse, human, rat only
foreach i (gene2accession gene2pubmed gene2refseq gene_info gene_history)
rm -rf $i.mgi
grep "^${MOUSETAXID}" $i > $i.mgi
grep "^${HUMANTAXID}" $i >> $i.mgi
grep "^${RATTAXID}" $i >> $i.mgi
end

# split up gene_info.mgi into gene_info.bcp, gene_dbxref.bcp, gene_synonym.bcp
cd ${EGINSTALLDIR}
./geneinfo.py >>& ${LOG}

# strip version numbers out of gene2accession.mgi, gene2refseq.mgi
./stripversion.py >>& ${LOG}

# truncate existing tables
${RADAR_DBSCHEMADIR}/table/DP_EntrezGene_truncate.logical >>& ${LOG}
${RADAR_DBSCHEMADIR}/table/DP_HomoloGene_truncate.object >>& ${LOG}

# drop indexes
${RADAR_DBSCHEMADIR}/index/DP_EntrezGene_drop.logical >>& ${LOG}
${RADAR_DBSCHEMADIR}/index/DP_HomoloGene_drop.object >>& ${LOG}

# bcp new data into tables
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_Accession in ${EGINPUTDIR}/gene2accession.new -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_Info in ${EGINPUTDIR}/gene_info.bcp -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_DBXRef in ${EGINPUTDIR}/gene_dbxref.bcp -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_PubMed in ${EGINPUTDIR}/gene2pubmed.mgi -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_RefSeq in ${EGINPUTDIR}/gene2refseq.new -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_Synonym in ${EGINPUTDIR}/gene_synonym.bcp -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_History in ${EGINPUTDIR}/gene_history.mgi -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_HomoloGene in ${EGINPUTDIR}/homologene.data -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}
cat ${RADAR_DBPASSWORDFILE} | bcp ${RADAR_DBNAME}..DP_EntrezGene_MIM in ${EGINPUTDIR}/mim2gene -c -t\\t -S${RADAR_DBSERVER} -U${RADAR_DBUSER} >>& ${LOG}

# create indexes
${RADAR_DBSCHEMADIR}/index/DP_EntrezGene_create.logical >>& ${LOG}
${RADAR_DBSCHEMADIR}/index/DP_HomoloGene_create.object >>& ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${RADAR_DBNAME}
go

/* convert the EG mapPosition values to MGI format (remove the leading chromosome value) */

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 3, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID})
and mapPosition like '[12][0-9]%'
go

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 2, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID})
and mapPosition like '[1-9]%'
go

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 2, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID})
and mapPosition like '[XY]%'
go

update DP_EntrezGene_Info
set chromosome = 'MT'
where taxID in (${HUMANTAXID}, ${RATTAXID})
and chromosome = 'mitochondrion'
go

update DP_EntrezGene_Info
set chromosome = 'UN'
where taxID in (${MOUSETAXID}, ${HUMANTAXID}, ${RATTAXID})
and chromosome in ('Un', 'unknown', '-')
go

update DP_EntrezGene_Info
set chromosome = 'XY'
where taxID in (${MOUSETAXID}, ${HUMANTAXID}, ${RATTAXID})
and chromosome = 'X|Y'
go

EOSQL

date >> ${LOG}

