#!/bin/csh -f

#
# Program:
#	createSets.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Create EG and MGI sets for given taxonimical ID
#	that will be used for "bucketizing".
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

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating sets..." | tee -a ${LOG}
date | tee -a ${LOG}

#cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0

delete from WRK_EntrezGene_EGSet where taxID = ${TAXID}
;

delete from WRK_EntrezGene_MGISet where taxID = ${TAXID}
;

EOSQL

# drop indexes
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_EGSet_drop.object | tee -a ${LOG}
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_MGISet_drop.object | tee -a ${LOG}

#cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0
 
/***** MGI *****/

/* set of all EG IDs (for markers)... */

insert into WRK_EntrezGene_MGISet
select ${TAXID}, a.accID, a.accID, 'EG'
from MRK_Marker m, ACC_Accession a
where m._Organism_key = ${ORGANISM}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
;

/* set of symbols that do not have EG ids */

CREATE TEMP TABLE noeg
as select m.symbol, m._Marker_key
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select 1 from ACC_Accession a
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY})
;

create index idx1 on noeg(_Marker_key)
;

insert into WRK_EntrezGene_MGISet
select ${TAXID}, symbol, symbol, 'Symbol'
from noeg
;

/* curated GenBank IDs for symbols that do not have EG ids */

insert into WRK_EntrezGene_MGISet
select distinct ${TAXID}, n.symbol, a.accID, 'Gen'
from noeg n, ACC_Accession a
where n._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
;

/***** EntrezGene *****/

/* set of all EG IDs */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.geneID, 'EG'
from DP_EntrezGene_Info e
where e.taxID = ${TAXID}
;

/* EG symbols */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.symbol, 'Symbol'
from DP_EntrezGene_Info e
where e.taxID = ${TAXID}
;

/* RNA GenBank IDs */

insert into WRK_EntrezGene_EGSet
select distinct e.taxID, e.geneID, e.rna, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${TAXID}
and e.rna != '-'
;

/* DNA GenBank IDs... */

insert into WRK_EntrezGene_EGSet
select distinct e.taxID, e.geneID, e.genomic, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${TAXID}
and e.genomic != '-'
;

EOSQL
 
# create indexes
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_EGSet_create.object | tee -a ${LOG}
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_MGISet_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating sets." | tee -a ${LOG}
