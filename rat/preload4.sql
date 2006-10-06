#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${REPORTFILE}

isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${MGD_DBNAME}
go

print ""
print "Bucket 4:  Duplicate Rat Symbols found in MGI"
print ""

select symbol
from MRK_Marker
where _Organism_key = ${RATSPECIESKEY}
group by symbol having count(*) > 1
order by symbol
go

quit

END

