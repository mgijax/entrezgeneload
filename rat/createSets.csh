#!/bin/csh -fx

#
# Create Sets for Rat Processing
#
# Usage:  createSets.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating rat sets..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

delete from WRK_EntrezGene_EGSet where taxID = ${RATTAXID}
go

delete from WRK_EntrezGene_MGISet where taxID = ${RATTAXID}
go

EOSQL

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_EGSet_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_MGISet_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
/***** MGI *****/

use ${DBNAME}
go

/* set of all EG IDs (for rat markers)... */

insert into ${RADARDB}..WRK_EntrezGene_MGISet
select ${RATTAXID}, a.accID, a.accID, 'EG'
from MRK_Marker m, ACC_Accession a
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
go

/* set of rat symbols that do not have EG ids */

select m.symbol, m._Marker_key
into #noeg
from MRK_Marker m
where m._Organism_key = ${RATSPECIESKEY}
and not exists (select 1 from ACC_Accession a
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY})
go

create index idx1 on #noeg(_Marker_key)
go

insert into ${RADARDB}..WRK_EntrezGene_MGISet
select ${RATTAXID}, symbol, symbol, 'Symbol'
from #noeg
go

/* curated GenBank IDs for rat symbols that do not have EG ids */

insert into ${RADARDB}..WRK_EntrezGene_MGISet
select ${RATTAXID}, n.symbol, a.accID, 'Gen'
from #noeg n, ACC_Accession a
where n._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
go

/***** EntrezGene *****/

use ${RADARDB}
go

/* set of all EG IDs */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.geneID, 'EG'
from DP_EntrezGene_Info e
where e.taxID = ${RATTAXID}
go

/* EG symbols */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.symbol, 'Symbol'
from DP_EntrezGene_Info e
where e.taxID = ${RATTAXID}
go

/* RNA GenBank IDs */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.rna, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${RATTAXID}
and e.rna != '-'
go

/* DNA GenBank IDs... */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.genomic, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${RATTAXID}
and e.genomic != '-'
go

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_EGSet_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_MGISet_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating rat sets." | tee -a ${LOG}
