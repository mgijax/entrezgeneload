#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 2: New EntrezGene IDs Processed"
print ""
print "     New EntrezGene IDs added to MGI Human symbol based on Symbol and Seq ID match"
print ""

select e.accID, m.symbol
from ${RADARDB}..WRK_EntrezGene_Bucket0 e, MRK_Marker m
where e.taxID = ${HUMANTAXID}
and e._LogicalDB_key = ${LOGICALEGKEY}
and e._Object_key = m._Marker_key
order by e.accID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

