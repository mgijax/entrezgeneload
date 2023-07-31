#!/bin/csh -f

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
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 07/23/2013	lec
#	- TR11317/11195/OMIM/mim2gene_medgen
#
# 06/14/2012 - lec
#	- TR10994/postgres/exporter
#	- remove children from parents of DP_EntrezGene_Info that do not exist
#	  this will cleanup foreign key referential integrity issues
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
cp ${FTPDATA1}/mim2gene_medgen ${EGINPUTDIR}

# uncompress the files
cd ${EGINPUTDIR}
foreach i (*.gz)
/usr/bin/gunzip -f $i >>& ${LOG}
end

#
# parse out mouse, human, rat only
# also strips out comments from input file
#
foreach i (gene2accession gene2pubmed gene2refseq gene_info gene_history)
rm -rf $i.mgi
grep "^${MOUSETAXID}" $i > $i.mgi
grep "^${HUMANTAXID}" $i >> $i.mgi
grep "^${RATTAXID}" $i >> $i.mgi
grep "^${DOGTAXID}" $i >> $i.mgi
grep "^${CHIMPTAXID}" $i >> $i.mgi
grep "^${CATTLETAXID}" $i >> $i.mgi
grep "^${CHICKENTAXID}" $i >> $i.mgi
grep "^${ZEBRAFISHTAXID}" $i >> $i.mgi
grep "^${MONKEYTAXID}" $i >> $i.mgi
grep "^${XENOPUSTAXID}" $i >> $i.mgi
grep "^${XENOPUSLAEVISTAXID}" $i >> $i.mgi
end

#
# strips out comments from input file
#
foreach i (mim2gene_medgen)
rm -rf $i.mgi
grep "^[0-9]" $i | cut -f1-5 > $i.mgi
end

# split up gene_info.mgi into gene_info.bcp, gene_dbxref.bcp, gene_synonym.bcp
${PYTHON} ${ENTREZGENELOAD}/geneinfo.py >>& ${LOG}

# strip version numbers out of gene2accession.mgi, gene2refseq.mgi
${PYTHON} ${ENTREZGENELOAD}/stripversion.py >>& ${LOG}

# truncate existing tables
${RADAR_DBSCHEMADIR}/table/DP_EntrezGene_truncate.logical >>& ${LOG}

# drop indexes
${RADAR_DBSCHEMADIR}/index/DP_EntrezGene_drop.logical >>& ${LOG}

# bcp new data into tables
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_Info ${EGINPUTDIR} gene_info.bcp "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_Accession ${EGINPUTDIR} gene2accession.new "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_DBXRef ${EGINPUTDIR} gene_dbxref.bcp "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_PubMed ${EGINPUTDIR} gene2pubmed.mgi "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_RefSeq ${EGINPUTDIR} gene2refseq.new "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_Synonym ${EGINPUTDIR} gene_synonym.bcp "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_History ${EGINPUTDIR} gene_history.mgi "\t" "\n" radar
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} DP_EntrezGene_MIM ${EGINPUTDIR} mim2gene_medgen.mgi "\t" "\n" radar

# create indexes
${RADAR_DBSCHEMADIR}/index/DP_EntrezGene_create.logical >>& ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
/* convert the EG mapPosition values to MGI format (remove the leading chromosome value) */

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 3, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID}, ${DOGTAXID}, ${CHIMPTAXID}, ${CATTLETAXID}, ${CHICKENTAXID}, ${ZEBRAFISHTAXID}, ${MONKEYTAXID}, ${XENOPUSTAXID})
and mapPosition SIMILAR To '(1|2|3)(0|1|2|3|4|5|6|7|8|9)%'
;

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 2, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID}, ${DOGTAXID}, ${CHIMPTAXID}, ${CATTLETAXID}, ${CHICKENTAXID}, ${ZEBRAFISHTAXID}, ${MONKEYTAXID}, ${XENOPUSTAXID})
and mapPosition SIMILAR TO '(0|1|2|3|4|5|6|7|8|9)%'
;

update DP_EntrezGene_Info
set mapPosition = substring(mapPosition, 2, 100)
where taxID in (${HUMANTAXID}, ${RATTAXID})
and mapPosition SIMILAR TO '(X|Y)%'
;

update DP_EntrezGene_Info set chromosome = 'UN' where chromosome in ('Un', 'unknown', '-') ;
update DP_EntrezGene_Info set chromosome = 'UN' where chromosome like '%|Un' ;
update DP_EntrezGene_Info set chromosome = 'XY' where chromosome = 'X|Y' ;
update DP_EntrezGene_Info set chromosome = 'UN' where chromosome like '%|%' ;

delete from DP_EntrezGene_Accession
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_Accession.geneID = DP_EntrezGene_Info.geneID)
;

delete from DP_EntrezGene_Accession where status = 'SUPPRESSED';

delete from  DP_EntrezGene_DBXRef
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_DBXRef.geneID = DP_EntrezGene_Info.geneID)
;

delete from  DP_EntrezGene_PubMed
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_PubMed.geneID = DP_EntrezGene_Info.geneID)
;

delete from  DP_EntrezGene_RefSeq
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_RefSeq.geneID = DP_EntrezGene_Info.geneID)
;

delete from  DP_EntrezGene_Synonym
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_Synonym.geneID = DP_EntrezGene_Info.geneID)
;

delete from  DP_EntrezGene_History 
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_History.geneID = DP_EntrezGene_Info.geneID)
;

delete from  DP_EntrezGene_MIM
where not exists (select DP_EntrezGene_Info.* from DP_EntrezGene_Info
	where DP_EntrezGene_MIM.geneID = DP_EntrezGene_Info.geneID)
;

EOSQL

date >> ${LOG}

