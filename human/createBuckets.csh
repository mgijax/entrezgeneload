#!/bin/csh -f

#
# Create Buckets for Human Processing
#
# Usage:  createBuckets.sh
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating human buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

${ENTREZGENELOAD}/commonBuckets-1.csh | tee -a ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
/***** HGNC ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HGNCPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HGNCPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HGNCPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_DBXRef e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
;

/***** OMIM Gene ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, 'OMIM:' || e.mimID, ${OMIMPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_MIM e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.annotationType = 'gene'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, 'OMIM:' || e.mimID, ${OMIMPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_MIM e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = e.geneID
and e.annotationType = 'gene'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, 'OMIM:' || e.mimID, ${OMIMPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_MIM e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.annotationType = 'gene'
;

EOSQL
 
${ENTREZGENELOAD}/commonBuckets-2.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating human buckets." | tee -a ${LOG}
