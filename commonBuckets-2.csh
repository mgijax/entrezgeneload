#!/bin/csh -fx

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

cd `dirname $0` && source ./Configuration

setenv DATADIR $1
setenv TAXID $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating buckets step 2..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
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
 
./createRADARindexes.csh | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating buckets step 2." | tee -a ${LOG}
