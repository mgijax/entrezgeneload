#!/bin/csh -fx

#
# Create Buckets for Rat Processing
#
# Usage:  createBuckets.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating rat buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

delete from WRK_EntrezGene_Bucket0 where taxID = ${RATTAXID}
go

delete from WRK_EntrezGene_Nomen where taxID = ${RATTAXID}
go

delete from WRK_EntrezGene_Mapping where taxID = ${RATTAXID}
go

EOSQL

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Nomen_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Mapping_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

/***** 1:1 by EG id *****/

select distinct s1.geneID, s2.mgiID, s1.idType
into #bucket0
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${RATTAXID}
and s1.idType = 'EG'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${RATTAXID}
go

/***** For those markers that don't have an EG id *****/

/* must match on Symbol... */

select distinct s1.geneID, s2.mgiID
into #symatches
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${RATTAXID}
and s1.idType = 'Symbol'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${RATTAXID}
go

create index idx1 on #symatches(geneID)
create index idx2 on #symatches(mgiID)
go

/* and Gen */

insert into #bucket0
select distinct s1.geneID, s2.mgiID, s1.idType
from #symatches s, WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s.geneID = s1.geneID
and s1.taxID = ${RATTAXID}
and s.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${RATTAXID}
go

/***** Bucket 0 */

create index idx1 on #bucket0(mgiID)
create index idx2 on #bucket0(idType)
go

insert into WRK_EntrezGene_Bucket0
select ${RATTAXID}, m._Marker_key, ${LOGICALEGKEY}, b.mgiID, b.geneID, ${RATEGPRIVATE}
from #bucket0 b, ${DBNAME}..MRK_Marker m
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${RATSPECIESKEY}
go

/***** RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.mgiID, r.rna, ${REFSEQPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.mgiID, r.rna, ${REFSEQPRIVATE}
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${RATSPECIESKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/***** RGD *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, a._Object_key, ${LOGICALRGDKEY}, b.mgiID, e.locusTag, ${RGDPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_Info e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.locusTag like 'RGD%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, m._Marker_key, ${LOGICALRGDKEY}, b.mgiID, e.locusTag, ${RGDPRIVATE}
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_Info e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${RATSPECIESKEY}
and b.geneID = e.geneID
and e.locusTag like 'RGD%'
go

/***** RatMap *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, a._Object_key, ${LOGICALRATMAPKEY}, b.mgiID, e.dbXRefID, ${RATMAPPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXRefID like 'RATMAP%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${RATTAXID}, m._Marker_key, ${LOGICALRATMAPKEY}, b.mgiID, e.dbXRefID, ${RATMAPPRIVATE}
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${RATSPECIESKEY}
and b.geneID = e.geneID
and e.dbXRefID like 'RATMAP%'
go

/***** Nomen Bucket *****/

insert into WRK_EntrezGene_Nomen
select e.taxID, m._Marker_key, e.geneID, m.symbol, m.name, e.symbol, e.name
from DP_EntrezGene_Info e, ${DBNAME}..ACC_Accession a, ${DBNAME}..MRK_Marker m
where e.taxID = ${RATTAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and e.symbol not like 'RGD%'
and (e.symbol != m.symbol or e.name != m.name)
go

/***** Mapping Bucket *****/

insert into WRK_EntrezGene_Mapping
select e.taxID, m._Marker_key, e.geneID, m.chromosome, m.cytogeneticOffset, e.chromosome, e.mapPosition
from DP_EntrezGene_Info e, ${DBNAME}..ACC_Accession a, ${DBNAME}..MRK_Marker m
where e.taxID = ${RATTAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and (
(e.chromosome != '-' and e.chromosome not like '%|%' and e.chromosome != m.chromosome)
or 
(e.mapPosition != '-' and e.mapPosition not like '%|%' and e.mapPosition != m.cytogeneticOffset)
)
go

update WRK_EntrezGene_Mapping
set egMapPosition = null where egMapPosition = '-'
go

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Nomen_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Mapping_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating rat buckets." | tee -a ${LOG}