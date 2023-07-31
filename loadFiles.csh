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
update DP_EntrezGene_Info set chromosome = '1' where chromosome like '1|%' ;
update DP_EntrezGene_Info set chromosome = '2' where chromosome like '2|%' ;
update DP_EntrezGene_Info set chromosome = '3' where chromosome like '3|%' ;
update DP_EntrezGene_Info set chromosome = '4' where chromosome like '4|%' ;
update DP_EntrezGene_Info set chromosome = '5' where chromosome like '5|%' ;
update DP_EntrezGene_Info set chromosome = '6' where chromosome like '6|%' ;
update DP_EntrezGene_Info set chromosome = '7' where chromosome like '7|%' ;
update DP_EntrezGene_Info set chromosome = '8' where chromosome like '8|%' ;
update DP_EntrezGene_Info set chromosome = '9' where chromosome like '9|%' ;
update DP_EntrezGene_Info set chromosome = '10' where chromosome like '10|%' ;
update DP_EntrezGene_Info set chromosome = '11' where chromosome like '11|%' ;
update DP_EntrezGene_Info set chromosome = '12' where chromosome like '12|%' ;
update DP_EntrezGene_Info set chromosome = '13' where chromosome like '13|%' ;
update DP_EntrezGene_Info set chromosome = '14' where chromosome like '14|%' ;
update DP_EntrezGene_Info set chromosome = '15' where chromosome like '15|%' ;
update DP_EntrezGene_Info set chromosome = '16' where chromosome like '16|%' ;
update DP_EntrezGene_Info set chromosome = '17' where chromosome like '17|%' ;
update DP_EntrezGene_Info set chromosome = '18' where chromosome like '18|%' ;
update DP_EntrezGene_Info set chromosome = '19' where chromosome like '19|%' ;
update DP_EntrezGene_Info set chromosome = '20' where chromosome like '20|%' ;
update DP_EntrezGene_Info set chromosome = '21' where chromosome like '21|%' ;
update DP_EntrezGene_Info set chromosome = '22' where chromosome like '22|%' ;
update DP_EntrezGene_Info set chromosome = '23' where chromosome like '23|%' ;

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

