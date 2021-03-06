#!/bin/csh -f

#
# Create Common Buckets 2 for Processing
# Called sometime after Common Buckets 1
#
# Nomen bucket
# Mapping bucket
# Synonym bucket
#
# Usage:  commonBuckets-2.sh
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating buckets step 2..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
/***** Nomen Bucket *****/

insert into WRK_EntrezGene_Nomen
select e.taxID, m._Marker_key, e.geneID, m.symbol, m.name, e.symbol, e.name
from DP_EntrezGene_Info e, ACC_Accession a, MRK_Marker m
where e.taxID = ${TAXID}
and e.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a._Object_key = m._Marker_key
and (e.symbol != m.symbol or e.name != m.name)
;

/***** Mapping Bucket *****/

insert into WRK_EntrezGene_Mapping
select e.taxID, m._Marker_key, e.geneID, m.chromosome, m.cytogeneticOffset, e.chromosome, e.mapPosition
from DP_EntrezGene_Info e, ACC_Accession a, MRK_Marker m
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
;

update WRK_EntrezGene_Mapping
set egMapPosition = null where egMapPosition = '-'
;

/****** Synonym Bucket ******/

insert into WRK_EntrezGene_Synonym
select s.taxID, a._Object_key, s.geneID, s.synonym
from DP_EntrezGene_Synonym s, ACC_Accession a
where s.taxID = ${TAXID}
and s.geneID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
;

EOSQL
 
${ENTREZGENELOAD}/createRADARindexes.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating buckets step 2." | tee -a ${LOG}
