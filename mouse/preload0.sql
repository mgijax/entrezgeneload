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

select b.accID "EntrezGene Acc ID", m.symbol "MGI Symbol", b.mgiID "MGI Acc ID", mt.name "Type"
from ${RADARDB}..WRK_EntrezGene_Bucket0 b, MRK_Marker m, MRK_Types mt
where b.accID not like '[A-Z]%'
and b._Object_key = m._Marker_key
and m._Marker_Type_key = mt._Marker_Type_key
order by m.symbol, b._LogicalDB_key
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

