#!/bin/csh -fx

#
# Create Buckets for Human Processing
#
# Usage:  createBuckets.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating human buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

delete from WRK_EntrezGene_Bucket0 where taxID = ${HUMANTAXID}
go

delete from WRK_EntrezGene_Nomen where taxID = ${HUMANTAXID}
go

delete from WRK_EntrezGene_Mapping where taxID = ${HUMANTAXID}
go

delete from WRK_EntrezGene_Synonym where taxID = ${HUMANTAXID}
go

EOSQL

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Nomen_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Mapping_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Synonym_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

/***** 1:1 by EG id *****/

select distinct s1.geneID, s2.mgiID, s1.idType
into #bucket0
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${HUMANTAXID}
and s1.idType = 'EG'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${HUMANTAXID}
go

/***** For those markers that don't have an EG id *****/

/* must match on Symbol... */

select distinct s1.geneID, s2.mgiID
into #symatches
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${HUMANTAXID}
and s1.idType = 'Symbol'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${HUMANTAXID}
go

create index idx1 on #symatches(geneID)
create index idx2 on #symatches(mgiID)
go

/* and Gen */

insert into #bucket0
select distinct s1.geneID, s2.mgiID, s1.idType
from #symatches s, WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s.geneID = s1.geneID
and s1.taxID = ${HUMANTAXID}
and s.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${HUMANTAXID}
go

/***** 1:0 by EG id *****/
/* these records need to be added to MGI */

insert into #bucket0
select distinct s1.geneID, 'none', s1.idType
from WRK_EntrezGene_EGSet s1
where s1.taxID = ${HUMANTAXID}
and s1.idType = 'EG'
and not exists (select 1 from #symatches s where s1.geneID = s.geneID)
and not exists (select 1 from WRK_EntrezGene_MGISet s2
	where s1.compareID = s2.compareID
	and s1.idType = s2.idType
	and s2.taxID = ${HUMANTAXID})
go

/***** Bucket 0 */

create index idx1 on #bucket0(mgiID)
create index idx2 on #bucket0(idType)
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${HUMANEGPRIVATE}, 0
from #bucket0 b, ${DBNAME}..MRK_Marker m
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${HUMANEGPRIVATE}, 0
from #bucket0 b
where b.mgiID = 'none'
go

/***** RNA RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/***** Protein RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${HUMANREFSEQPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

/***** SwissProt ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${HUMANSPPRIVATE}, 1
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_Accession r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${HUMANSPPRIVATE}, 1
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_Accession r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${HUMANSPPRIVATE}, 1
from #bucket0 b, DP_EntrezGene_Accession r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.protein like '[A-Z][0-9][0-9][0-9][0-9][0-9]'
go

/***** HGNC ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.locusTag, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_Info e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.locusTag like 'HGNC:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.locusTag, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_Info e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = e.geneID
and e.locusTag like 'HGNC:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.locusTag, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, DP_EntrezGene_Info e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.locusTag like 'HGNC:%'
go

/***** OMIM Gene ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, e.mimID, ${HUMANOMIMPRIVATE}, 0
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_MIM e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.annotationType = 'gene'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, e.mimID, ${HUMANOMIMPRIVATE}, 0
from #bucket0 b, ${DBNAME}..MRK_Marker m, DP_EntrezGene_MIM e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = e.geneID
and e.annotationType = 'gene'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, e.mimID, ${HUMANOMIMPRIVATE}, 0
from #bucket0 b, DP_EntrezGene_MIM e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.annotationType = 'gene'
go

/***** Nomen Bucket *****/

insert into WRK_EntrezGene_Nomen
select e.taxID, m._Marker_key, e.geneID, m.symbol, m.name, e.symbol, e.name
from DP_EntrezGene_Info e, ${DBNAME}..ACC_Accession a, ${DBNAME}..MRK_Marker m
where e.taxID = ${HUMANTAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and (e.symbol != m.symbol or e.name != m.name)
go

/***** Mapping Bucket *****/

insert into WRK_EntrezGene_Mapping
select e.taxID, m._Marker_key, e.geneID, m.chromosome, m.cytogeneticOffset, e.chromosome, e.mapPosition
from DP_EntrezGene_Info e, ${DBNAME}..ACC_Accession a, ${DBNAME}..MRK_Marker m
where e.taxID = ${HUMANTAXID}
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
from DP_EntrezGene_Synonym s, ${DBNAME}..ACC_Accession a
where s.taxID = ${HUMANTAXID}
and s.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
go

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Nomen_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Mapping_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Synonym_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating human buckets." | tee -a ${LOG}
