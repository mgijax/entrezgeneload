#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 7 - MGI Acc ID Match; EntrezGene has SeqID; MGI has SeqID */

print ""
print "Bucket 7 - MGI Acc ID Match; EntrezGene has SeqID; MGI has SeqID; not in Bucket 0,1,2,3"
print ""

select distinct l.geneID "EntrezGene ID", la.genbankID "EntrezGene Seq ID", m.symbol "MGI Symbol", ma.accID "MGI Acc ID", maa.accID "MGI Seq ID"
from ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc la, ACC_Accession ma, MRK_Marker m, ACC_Accession maa
where l.taxID = ${MOUSETAXID}
and l.locusTag = ma.accID
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma.preferred = 1
and ma._Object_key = m._Marker_key
and m._Marker_Type_key in (1,7)
and l.geneID = la.geneID
and la.genbankID not like 'NM%'
and la.genbankID not like 'NC%'
and ma._Object_key = maa._Object_key
and maa._MGIType_key = ${MARKERTYPEKEY}
and maa._LogicalDB_key = ${LOGICALSEQKEY}
and not exists (select 1 from ${RADARDB}..WRK_LLBucket0 ll
where l.geneID = ll.llaccID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeNonGenes e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeSeqIDs e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeLLIDs e
where l.geneID = e.geneID)
order by la.genbankID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

