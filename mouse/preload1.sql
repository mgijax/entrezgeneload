#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 1 - EntrezGene IDs for non-Gene/Pseudogene Markers */

print ""
print "Bucket 1 - EntrezGene IDs which map to non Gene/Pseudogene MGI Markers"
print ""
print "    These records are excluded from processing because they contain"
print "    a MGI Acc ID which is not of marker type Gene or Pseudogene."
print ""

select e.geneID "EntrezGene ID", m.symbol "MGI Symbol", e.mgiID "MGI Acc ID", m.markerType "Type"
from ${RADARDB}..WRK_EntrezGene_ExcludeA e, MRK_Marker_View m
where e._Object_key = m._Marker_key
order by m.markerType, e.geneID, e.mgiID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

