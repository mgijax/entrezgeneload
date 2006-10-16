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

../commonBuckets-1.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY} | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0 | tee -a ${LOG}
 
use ${RADAR_DBNAME}
go

/***** HGNC ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_DBXRef e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_DBXRef e
where b.idType = 'Symbol'
and b.mgiID = m.symbol
and m._Organism_key = ${HUMANSPECIESKEY}
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, -1, ${LOGICALHGNCKEY}, b.geneID, b.mgiID, e.dbXrefID, ${HUMANHGNCPRIVATE}, 0
from #bucket0 b, DP_EntrezGene_DBXRef e
where b.mgiID = 'none'
and b.geneID = e.geneID
and e.dbXrefID like 'HGNC:%'
go

/***** OMIM Gene ids *****/

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, a._Object_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, e.mimID, ${HUMANOMIMPRIVATE}, 0
from #bucket0 b, ${MGD_DBNAME}..ACC_Accession a, DP_EntrezGene_MIM e
where b.idType = 'EG'
and b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and b.geneID = e.geneID
and e.annotationType = 'gene'
go

insert into WRK_EntrezGene_Bucket0
select distinct ${HUMANTAXID}, m._Marker_key, ${LOGICALOMIMKEY}, b.geneID, b.mgiID, e.mimID, ${HUMANOMIMPRIVATE}, 0
from #bucket0 b, ${MGD_DBNAME}..MRK_Marker m, DP_EntrezGene_MIM e
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

EOSQL
 
../commonBuckets-2.csh ${HUMANDATADIR} ${HUMANTAXID} | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating human buckets." | tee -a ${LOG}
