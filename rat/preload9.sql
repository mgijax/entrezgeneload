#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
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
and ma._LogicalDB_key = ${LOGICALLLKEY}
and not exists (select 1 from ${RADARDB}..WRK_LLRatRGDIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ${RADARDB}..WRK_LLRatRATMAPIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRATMAPKEY})
union
select m._Marker_key, m.symbol, name = substring(m.name,1,30), ma.locusID
from MRK_Marker m, ${RADARDB}..WRK_LLRatLLIDsToAdd ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Marker_key
and not exists (select 1 from ${RADARDB}..WRK_LLRatRGDIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ${RADARDB}..WRK_LLRatRATMAPIDsToAdd l
where m._Marker_key = l._Marker_key)
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
print "Bucket 9: MGD Rat Symbols with a LL ID, no RGD ID, no RatMap ID (the Yes-No-No set)"
print ""

select f.symbol "MGD Rat Symbol", f.name "MGD Rat Name", f.accID "LL ID"
from #yesnonoset f
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

