#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${MGD_DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${MGD_DBNAME}
go

set nocount on
go

/* Yes-No-No Set */

select m._Marker_key, m.symbol, name = substring(m.name,1,30), ma.accID
into #yesnonoset
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALEGKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRATMAPKEY})
go

set nocount off
go

print ""
print "Bucket 9: MGI Rat Symbols with a EG ID, no RGD ID, no RatMap ID (the Yes-No-No set)"
print ""

select f.symbol "MGI Rat Symbol", f.name "MGI Rat Name", f.accID "EG ID"
from #yesnonoset f
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

