#!/bin/csh -f

#
# Create Buckets for Zebrafish Processing
#
# Usage:  createBuckets.sh
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating zebrafish buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

${ENTREZGENELOAD}/commonBuckets-1.csh | tee -a ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
/***** ZDB ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, a._Object_key, ${LOGICALZFINKEY}, b.geneID, b.mgiID, substring(e.dbXrefID from 6), ${ZFINPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'ZFIN:%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, m._Marker_key, ${LOGICALZFINKEY}, b.geneID, b.mgiID, substring(e.dbXrefID from 6), ${ZFINPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${ORGANISM}
and b.geneID = e.geneID
and e.dbXrefID like 'ZFIN:%'
;

insert into WRK_EntrezGene_Bucket0
select distinct ${TAXID}, -1, ${LOGICALZFINKEY}, b.geneID, b.mgiID, substring(e.dbXrefID from 6), ${ZFINPRIVATE}, 0
from WRK_EntrezGene_Bucket0Tmp b, DP_EntrezGene_DBXRef e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.dbXrefID like 'ZFIN:%'
;

EOSQL
 
${ENTREZGENELOAD}/commonBuckets-2.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating zebrafish buckets." | tee -a ${LOG}
