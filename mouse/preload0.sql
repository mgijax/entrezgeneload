#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 0 - MGI Acc ID match; Seq ID match */

print ""
print "Bucket 0 - MGI Acc ID Match; Seq ID Match - Good to Load"
print ""
print "     1.  The EntrezGene MGI Acc ID matches the MGI Marker Acc ID. "
print "     2.  There is at least one Seq ID in common between the EntrezGene record and the MGI Marker."
print "     3.  The EntrezGene record does not exist in Bucket 1 or 2."
print "     4.  The EntrezGene/Seq ID record does not exist in Bucket 1 or 2."
print ""

select b.llaccID "EntrezGene Acc ID", k.symbol "MGI Symbol", b.accID "MGI Acc ID", k.markerType "Type"
from ${RADARDB}..WRK_LLBucket0 b, MRK_Marker_View k
where b._Object_key = k._Marker_key
order by k.symbol, b._LogicalDB_key
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

