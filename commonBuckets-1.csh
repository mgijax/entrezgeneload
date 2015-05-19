#!/bin/csh -f

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
 
${PG_RADAR_DBSCHEMADIR}/table/WRK_EntrezGene_Bucket0Tmp_truncate.object | tee -a ${LOG}
${PG_RADAR_DBSCHEMADIR}/table/WRK_EntrezGene_SyMatches_truncate.object | tee -a ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}

/***** 1:1 by EG id *****/
-- compare EG set vs. MGI set using a "comparsionID"
-- a "comparisonID": MGI id,  


insert into WRK_EntrezGene_Bucket0Tmp
select distinct s1.geneID, s2.mgiID, s1.idType
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${TAXID}
and s1.idType = 'EG'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${TAXID}
;

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
;

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
;

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
;

/***** Bucket 0 */

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${EGPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALEGKEY}, b.geneID, b.mgiID, b.geneID, ${EGPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b
where b.mgiID = 'none'
;

/***** RNA RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and r.rna like 'NM_%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and r.rna like 'NM_%'
;

/***** Protein RefSeq ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_RefSeq r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_RefSeq r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALREFSEQKEY}, b.geneID, b.mgiID, r.protein, ${REFSEQPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_RefSeq r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like 'NP_%' or r.protein like 'XP_%')
;

/***** SwissProt ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_Accession r
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_Accession r
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALSPKEY}, b.geneID, b.mgiID, r.protein, ${SPPRIVATE}, 1
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_Accession r
where b.mgiID = 'none'
and b.geneID = r.geneID
and (r.protein like '[O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9]'
or r.protein like '[A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9]')
;

EOSQL
 
date | tee -a ${LOG}
echo "End: creating buckets." | tee -a ${LOG}
