#!/bin/csh -fx

#
# Create Sets for Mouse Processing
#
# Usage:  createSets.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating mouse sets..." | tee -a ${LOG}
date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

delete from WRK_EntrezGene_EGSet where taxID = ${MOUSETAXID}
go

delete from WRK_EntrezGene_MGISet where taxID = ${MOUSETAXID}
go

EOSQL

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_EGSet_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_MGISet_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
/***** EntrezGene *****/

use ${RADARDB}
go

/* set of all EG MGI IDs... */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.locusTag, 'MGI'
from DP_EntrezGene_Info e
where e.taxID = ${MOUSETAXID}
and e.locusTag != '-'
and not exists (select 1 from WRK_EntrezGene_ExcludeA x where e.geneID = x.geneID)
and not exists (select 1 from WRK_EntrezGene_ExcludeC x where e.geneID = x.geneID)
go

/* RNA GenBank IDs */
/* excludes GenBank IDs that exist in any of the "excluded" buckets */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.rna, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${MOUSETAXID}
and e.rna != '-'
and not exists (select 1 from WRK_EntrezGene_ExcludeA x where e.geneID = x.geneID)
and not exists (select 1 from WRK_EntrezGene_ExcludeB x where e.rna = x.seqID)
and not exists (select 1 from WRK_EntrezGene_ExcludeC x where e.geneID = x.geneID)
go

/* DNA GenBank IDs... */
/* excludes GenBank IDs that exist in any of the "excluded" buckets */

insert into WRK_EntrezGene_EGSet
select e.taxID, e.geneID, e.genomic, 'Gen'
from DP_EntrezGene_Accession e
where e.taxID = ${MOUSETAXID}
and e.genomic != '-'
and not exists (select 1 from WRK_EntrezGene_ExcludeA x where e.geneID = x.geneID)
and not exists (select 1 from WRK_EntrezGene_ExcludeB x where e.genomic = x.seqID)
and not exists (select 1 from WRK_EntrezGene_ExcludeC x where e.geneID = x.geneID)
go

/***** MGI *****/

use ${DBNAME}
go

/* set of all MGI IDs (for mouse markers)... */

insert into ${RADARDB}..WRK_EntrezGene_MGISet
select ${MOUSETAXID}, a1.accID, a2.accID, 'MGI'
from ACC_Accession a1, ACC_Accession a2
where a1._MGIType_key = ${MARKERTYPEKEY}
and a1._LogicalDB_key = 1
and a1.prefixPart = 'MGI:'
and a1.preferred = 1
and a1._Object_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = 1
and a2.prefixPart = 'MGI:'
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_ExcludeA x where a1.accID = x.mgiID)
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_ExcludeC x where a1.accID = x.mgiID)
go

/* curated GenBank IDs... */

insert into ${RADARDB}..WRK_EntrezGene_MGISet
select ${MOUSETAXID}, a1.accID, a2.accID, 'Gen'
from ACC_Accession a1, ACC_Accession a2
where a1._MGIType_key = ${MARKERTYPEKEY}
and a1._LogicalDB_key = 1
and a1.prefixPart = 'MGI:'
and a1.preferred = 1
and a1._Object_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = ${LOGICALSEQKEY}
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_ExcludeA x where a1.accID = x.mgiID)
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_ExcludeB x where a2.accID = x.seqID)
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_ExcludeC x where a1.accID = x.mgiID)
go

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_EGSet_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_MGISet_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating mouse sets." | tee -a ${LOG}
