#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Duplicate Human Symbols found in MGD"
print ""

select symbol
from ${RADARDB}..WRK_LLMGIHumanDuplicates
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

