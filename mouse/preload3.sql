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

select e.geneID "EntrezGene ID", la.genbankID "Seq ID", m.symbol "MGI Symbol", a2.accID "MGI Acc ID"
from ${RADARDB}..WRK_LLExcludeLLIDs e, ${RADARDB}..DP_LLAcc la, ACC_Accession a1, MRK_Marker m, ACC_Accession a2
where e.geneID = la.geneID
and la.genbankID = a1.accID
and e._Object_key = m._Marker_key
and e._Object_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2.prefixPart = "MGI:"
and a2._LogicalDB_key = 1
and a2.preferred = 1
and a1._Object_key = a2._Object_key
and a1._MGIType_key = ${MARKERTYPEKEY}
order by e.geneID, m.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

