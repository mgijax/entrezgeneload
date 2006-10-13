#!/bin/csh
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

print ""
print "Duplicate Chimpanzee Symbols found in MGI"
print ""

select symbol
from MRK_Marker
where _Organism_key = ${CHIMPSPECIESKEY}
group by symbol having count(*) > 1
order by symbol
go

quit

END

