#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 4 - MGI Acc ID Match; EntrezGene has no SeqID; MGI has no SeqID */

print ""
print "Bucket 4 - MGI Acc ID Match; EntrezGene has no SeqID; MGI has no SeqID; not in Bucket 1,2,3"
print ""

select distinct l.geneID "EntrezGene ID", m.symbol "MGI Symbol", ma.accID "MGI Acc ID"
from ${RADARDB}..DP_EntrezGene_Info l, ACC_Accession ma, MRK_Marker m
where l.taxID = ${MOUSETAXID}
and l.locusTag = ma.accID
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma.preferred = 1
and ma._Object_key = m._Marker_key
and not exists
(select 1 from ${RADARDB}..DP_LLAcc la
where l.geneID = la.geneID
and la.genbankID not like 'NM%')
and not exists (select 1 from MRK_Acc_View maa
where ma._Object_key = maa._Object_key
and maa._LogicalDB_key = 9)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeNonGenes e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeSeqIDs e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeLLIDs e
where l.geneID = e.geneID)
order by m.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

