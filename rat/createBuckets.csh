#!/bin/csh -fx

#
# Create Buckets for Rat Processing
#
# Usage:  createBuckets.sh
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating rat buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

../commonBuckets-1.csh | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
go

/***** RGD *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALRGDKEY}, b.geneID, b.mgiID, e.dbXrefID, ${RGDPRIVATE}, 0
from tempdb..bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'RGD:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALRGDKEY}, b.geneID, b.mgiID, e.dbXrefID, ${RGDPRIVATE}, 0
from tempdb..bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = e.geneID
and e.dbXrefID like 'RGD:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALRGDKEY}, b.geneID, b.mgiID, e.dbXrefID, ${RGDPRIVATE}, 0
from tempdb..bucket0 b, DP_EntrezGene_DBXRef e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.dbXrefID like 'RGD:%'
go

/***** RatMap *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALRATMAPKEY}, b.geneID, b.mgiID, substring(e.dbXrefID,8,50), ${RATMAPPRIVATE}, 0
from tempdb..bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'RATMAP%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALRATMAPKEY}, b.geneID, b.mgiID, substring(e.dbXrefID,8,50), ${RATMAPPRIVATE}, 0
from tempdb..bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = e.geneID
and e.dbXrefID like 'RATMAP%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALRATMAPKEY}, b.geneID, b.mgiID, substring(e.dbXrefID,8,50), ${RATMAPPRIVATE}, 0
from tempdb..bucket0 b, DP_EntrezGene_DBXRef e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.dbXrefID like 'RATMAP%'
go

/***** Nomen Bucket *****/

insert into WRK_EntrezGene_Nomen
select e.taxID, m._Marker_key, e.geneID, m.symbol, m.name, e.symbol, e.name
from DP_EntrezGene_Info e, ${MGD_DBNAME}..ACC_Accession a, ${MGD_DBNAME}..MRK_Marker m
where e.taxID = ${TAXID}
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
from DP_EntrezGene_Info e, ${MGD_DBNAME}..ACC_Accession a, ${MGD_DBNAME}..MRK_Marker m
where e.taxID = ${TAXID}
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

/****** Synonym Bucket ******/

insert into WRK_EntrezGene_Synonym
select s.taxID, a._Object_key, s.geneID, s.synonym
from DP_EntrezGene_Synonym s, ${MGD_DBNAME}..ACC_Accession a
where s.taxID = ${TAXID}
and s.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
go

EOSQL
 
../createRADARindexes.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating rat buckets." | tee -a ${LOG}
