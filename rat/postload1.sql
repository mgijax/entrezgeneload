#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "MGD Rat Symbol with no LL ID but LL ID in Rat Symbol Notes"
print ""

select m.symbol, name = substring(m.name,1,30), substring(n.note, charindex("LLID", n.note), 15)
from MRK_Marker m, MRK_Notes n
where m._Marker_key = n._Marker_key
and n.note like '%LLID%'
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

