#!/bin/csh -f
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

print ""
print "Bucket 5: New Monkey Markers Added to MGI"
print ""

select b.accID "EG ID", e.symbol "Symbol", e.name "Name", e.chromosome "Chromosome", e.mapPosition "Map Position"
from ${RADAR_DBNAME}..WRK_EntrezGene_Bucket0 b, ${RADAR_DBNAME}..DP_EntrezGene_Info e
where b.taxID = ${TAXID}
and b._Object_key = -1
and b._LogicalDB_key = ${LOGICALEGKEY}
and b.accID = e.geneID
order by e.symbol
go

quit

END

