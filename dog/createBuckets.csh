#!/bin/csh -fx

#
# Create Buckets for Dog Processing
#
# Usage:  createBuckets.csh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${DOGDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating dog buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

../deleteRADAR.csh ${DOGTAXID} | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
go

/***** 1:1 by EG id *****/

select distinct s1.geneID, s2.mgiID, s1.idType
into #bucket0
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${DOGTAXID}
and s1.idType = 'EG'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${DOGTAXID}
go

/***** For those markers that don't have an EG id *****/

/* must match on Symbol... */

select distinct s1.geneID, s2.mgiID
into #symatches
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${DOGTAXID}
and s1.idType = 'Symbol'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${DOGTAXID}
go

create index idx1 on #symatches(geneID)
create index idx2 on #symatches(mgiID)
go

/* and Gen */

insert into #bucket0
select distinct s1.geneID, s2.mgiID, s1.idType
from #symatches s, WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s.geneID = s1.geneID
and s1.taxID = ${DOGTAXID}
and s.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${DOGTAXID}
go

/***** 1:0 by EG id *****/
/* these records need to be added to MGI */

insert into #bucket0
select distinct s1.geneID, 'none', s1.idType
from WRK_EntrezGene_EGSet s1
where s1.taxID = ${DOGTAXID}
and s1.idType = 'EG'
and not exists (select 1 from #symatches s where s1.geneID = s.geneID)
and not exists (select 1 from WRK_EntrezGene_MGISet s2
	where s1.compareID = s2.compareID
	and s1.idType = s2.idType
	and s2.taxID = ${DOGTAXID})
go

/***** Bucket 0 */

create index idx1 on #bucket0(mgiID)
create index idx2 on #bucket0(idType)
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, m._Marker_key, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${DOGEGPRIVATE}, 0
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${DOGSPECIESKEY}
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, -1, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${DOGEGPRIVATE}, 0
from #bucket0 b
where b.mgiID = 'none'
go

/***** RNA RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${DOGSPECIESKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/***** Protein RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${DOGSPECIESKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${DOGREFSEQPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

/***** SwissProt ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, a._Object_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${DOGSPPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_Accession r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, m._Marker_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${DOGSPPRIVATE}, 1
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_Accession r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${DOGSPECIESKEY}
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${DOGTAXID}, -1, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${DOGSPPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_Accession r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

/***** Nomen Bucket *****/

insert into WRK_EntrezGene_Nomen
select e.taxID, m._Marker_key, e.geneID, m.symbol, m.name, e.symbol, e.name
from DP_EntrezGene_Info e, ${MGD_DBNAME}..ACC_Accession a, ${MGD_DBNAME}..MRK_Marker m
where e.taxID = ${DOGTAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and (e.symbol != m.symbol or e.name != m.name)
go

/***** Mapping Bucket *****/

insert into WRK_EntrezGene_Mapping
select e.taxID, m._Marker_key, e.geneID, m.chromosome, m.cytogeneticOffset, e.chromosome, e.mapPosition
from DP_EntrezGene_Info e, ${MGD_DBNAME}..ACC_Accession a, ${MGD_DBNAME}..MRK_Marker m
where e.taxID = ${DOGTAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and (
(e.chromosome != m.chromosome)
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
where s.taxID = ${DOGTAXID}
and s.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
go

EOSQL
 
../createRADARindexes.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating dog buckets." | tee -a ${LOG}
