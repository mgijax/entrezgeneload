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

select e.geneID "EntrezGene ID", m.symbol "MGI Symbol", e.mgiID "MGI Acc ID", mt.name "Type"
from ${RADARDB}..WRK_EntrezGene_ExcludeA e, ACC_Accession a, MRK_Marker m, MRK_Types mt
where e.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = m._Marker_key
and m._Marker_Type_key = mt._Marker_Type_key
order by mt.name, e.geneID, e.mgiID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

