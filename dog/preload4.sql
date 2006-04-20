#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${MGD_DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${MGD_DBNAME}
go

print ""
print "Duplicate Dog Symbols found in MGI"
print ""

select symbol
from MRK_Marker
where _Organism_key = ${DOGSPECIESKEY}
group by symbol having count(*) > 1
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

