#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Duplicate LL IDs found in LL file"
print ""

select locusID "LL ID", gsdbID "GDB ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLHumanDuplicates
group by locusID having count(*) > 1
order by locusID
go

print ""
print "Duplicate LL Symbols found in LL file"
print ""

select locusID "LL ID", gsdbID "GDB ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLHumanDuplicates
where osymbol is not null
order by osymbol
go

print ""
print "Duplicate GDB IDs found in LL file"
print ""

select locusID "LL ID", gsdbID "GDB ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLHumanDuplicates
where gsdbID is not null
order by gsdbID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

