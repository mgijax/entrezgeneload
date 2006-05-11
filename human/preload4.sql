#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${MGD_DBSERVER} -U${MGD_PUBLICUSER} -P${MGD_DBPUBLICPASSWORDFILE} -w300 <<END >> ${REPORTFILE}

use ${MGD_DBNAME}
go

print ""
print "Duplicate Human Symbols found in MGI"
print ""

select symbol
from MRK_Marker
where _Organism_key = ${HUMANSPECIESKEY}
group by symbol having count(*) > 1
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

