#!/bin/csh -f
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

print ""
print "Bucket 2: New EntrezGene IDs Processed"
print ""
print "     New EntrezGene IDs added to MGI Xenopus symbol based on Symbol and Seq ID match"
print ""

select e.accID, m.symbol
from ${RADAR_DBNAME}..WRK_EntrezGene_Bucket0 e, MRK_Marker m
where e.taxID = ${TAXID}
and e._LogicalDB_key = ${LOGICALEGKEY}
and e._Object_key = m._Marker_key
order by e.accID
go

quit

END

