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

select locusID "LL ID", gsdbID "RGD ID", ratmapID, "RatMap ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLRatDuplicates
group by locusID having count(*) > 1
order by locusID
go

print ""
print "Duplicate LL Symbols found in LL file"
print ""

select locusID "LL ID", gsdbID "RGD ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLRatDuplicates
where osymbol is not null
group by osymbol having count(*) > 1
order by osymbol
go

print ""
print "Duplicate RGD IDs found in LL file"
print ""

select locusID "LL ID", gsdbID "RGD ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLRatDuplicates
where gsdbID is not null
group by gsdbID having count(*) > 1
order by gsdbID
go

print ""
print "Duplicate RatMap IDs found in LL file"
print ""

select locusID "LL ID", ratmapID "RatMap ID", osymbol "LL Official Symbol"
from ${RADARDB}..WRK_LLRatDuplicates
where ratmapID is not null
group by ratmapID having count(*) > 1
order by ratmapID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

