#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "MGD Rat Symbol Mapping Updates"
print ""

select m.locusID, l.gsdbID, m.symbol, m.llChr, substring(m.llOff, 1, 20) "llOff"
from ${RADARDB}..WRK_LLRatMappingUpdates m, ${RADARDB}..DP_LL l
where m.locusID = l.locusID
order by m.locusID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

