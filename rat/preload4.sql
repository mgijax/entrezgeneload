#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
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

cat ${REPORTTRAILER} >> ${REPORTFILE}

