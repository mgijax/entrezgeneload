#!/bin/csh -fx

#
# Create Common Buckets Set 1 for Processing
#
# Usage:  commonBuckets-1.csh
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

${ENTREZGENELOAD}/deleteRADAR.csh ${TAXID} | tee -a ${LOG}
 
${RADAR_DBSCHEMADIR}/table/WRK_EntrezGene_Bucket0Tmp_truncate.object | tee -a ${LOG}
${RADAR_DBSCHEMADIR}/table/WRK_EntrezGene_SyMatches_truncate.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
go

/***** 1:1 by EG id *****/

insert into WRK_EntrezGene_Bucket0Tmp
select distinct s1.geneID, s2.mgiID, s1.idType
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${TAXID}
and s1.idType = 'EG'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${TAXID}
go

/***** For those markers that don't have an EG id *****/

/* must match on Symbol... */

insert into WRK_EntrezGene_SyMatches
select distinct s1.geneID, s2.mgiID
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${TAXID}
and s1.idType = 'Symbol'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${TAXID}
go

/* and Gen */

insert into WRK_EntrezGene_Bucket0Tmp
select distinct s1.geneID, s2.mgiID, s1.idType
from WRK_EntrezGene_SyMatches s, WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s.geneID = s1.geneID
and s1.taxID = ${TAXID}
and s.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${TAXID}
go

/***** 1:0 by EG id *****/
/* these records need to be added to MGI */

insert into WRK_EntrezGene_Bucket0Tmp
select distinct s1.geneID, 'none', s1.idType
from WRK_EntrezGene_EGSet s1
where s1.taxID = ${TAXID}
and s1.idType = 'EG'
and not exists (select 1 from WRK_EntrezGene_SyMatches s where s1.geneID = s.geneID)
and not exists (select 1 from WRK_EntrezGene_MGISet s2
	where s1.compareID = s2.compareID
	and s1.idType = s2.idType
	and s2.taxID = ${TAXID})
go

/***** Bucket 0 */

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${EGPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..MRK_Marker m
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${EGPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b
where b.mgiID = 'none'
go

/***** RNA RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/***** Protein RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
go

/***** SwissProt ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_Accession r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_Accession r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
go

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_Accession r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
go

EOSQL
 
date | tee -a ${LOG}
echo "End: creating buckets." | tee -a ${LOG}
