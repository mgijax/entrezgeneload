#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 3 - EntrezGene IDs w/ > 1 MGI Marker Match */

print ""
print "Bucket 3 - EntrezGene IDs with different Seq IDs which map to different MGI Markers"
print ""
print "     EntrezGene records which are excluded from processing because they contain "
print "     more than one Seq ID, and different Seq IDs map to different MGI Markers."
print ""

select e.geneID "EntrezGene ID", ea.rna "Seq ID", m.symbol "MGI Symbol", e.mgiID "MGI Acc ID"
from ${RADARDB}..WRK_EntrezGene_ExcludeC e, ${RADARDB}..DP_EntrezGene_Accession ea, 
ACC_Accession a1, ACC_Accession a2, MRK_Marker m
where e.geneID = ea.geneID
and e.mgiID = a1.accID
and a1._MGIType_key = ${MARKERTYPEKEY}
and ea.rna = a2.accID
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = ${LOGICALSEQKEY}
and a1._Object_key = a2._Object_key
and a1._Object_key = m._Marker_key
order by e.geneID, m.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

