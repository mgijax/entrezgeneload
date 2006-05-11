#!/bin/csh -fx

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

setenv DATADIR $1
setenv TAXID $2
setenv ORGANISM $3

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating sets..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
go

delete from WRK_EntrezGene_EGSet where taxID = ${TAXID}
go

delete from WRK_EntrezGene_MGISet where taxID = ${TAXID}
go

EOSQL

# drop indexes
${RADAR_DBSCHEMA}/index/WRK_EntrezGene_EGSet_drop.object | tee -a ${LOG}
${RADAR_DBSCHEMA}/index/WRK_EntrezGene_MGISet_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
/***** MGI *****/

use ${MGD_DBNAME}
go

/* set of all EG IDs (for markers)... */

insert into ${RADAR_DBNAME}..WRK_EntrezGene_MGISet
select ${TAXID}, a.accID, a.accID, 'EG'
from MRK_Marker m, ACC_Accession a
where m._Organism_key = ${ORGANISM}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
go

/* set of symbols that do not have EG ids */

select m.symbol, m._Marker_key
into #noeg
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select 1 from ACC_Accession a
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY})
go

create index idx1 on #noeg(_Marker_key)
go

insert into ${RADAR_DBNAME}..WRK_EntrezGene_MGISet
select ${TAXID}, symbol, symbol, 'Symbol'
from #noeg
go

/* curated GenBank IDs for symbols that do not have EG ids */

insert into ${RADAR_DBNAME}..WRK_EntrezGene_MGISet
select distinct ${TAXID}, n.symbol, a.accID, 'Gen'
from #noeg n, ACC_Accession a
where n._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
go

/***** EntrezGene *****/

use ${RADAR_DBNAME}
go

/* set of all EG IDs */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.geneID, 'EG'
from DP_EntrezGene_Info e
where e.taxID = ${TAXID}
go

/* EG symbols */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.symbol, 'Symbol'
from DP_EntrezGene_Info e
where e.taxID = ${TAXID}
go

/* RNA GenBank IDs */

insert into WRK_EntrezGene_EGSet
select distinct e.taxID, e.geneID, e.rna, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${TAXID}
and e.rna != '-'
go

/* DNA GenBank IDs... */

insert into WRK_EntrezGene_EGSet
select distinct e.taxID, e.geneID, e.genomic, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${TAXID}
and e.genomic != '-'
go

EOSQL
 
# create indexes
${RADAR_DBSCHEMA}/index/WRK_EntrezGene_EGSet_create.object | tee -a ${LOG}
${RADAR_DBSCHEMA}/index/WRK_EntrezGene_MGISet_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating sets." | tee -a ${LOG}
