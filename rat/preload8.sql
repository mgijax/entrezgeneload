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

/* No-No-Yes Set */

select m._Marker_key, m.symbol, name = substring(m.name,1,30), ma.accID
into #nonoyesset
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRATMAPKEY}
and not exists (select 1 from ${RADARDB}..WRK_LLRatLLIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ${RADARDB}..WRK_LLRatRGDIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
union
select m._Marker_key, m.symbol, name = substring(m.name,1,30), ma.ratmapID
from MRK_Marker m, ${RADARDB}..WRK_LLRatRATMAPIDsToAdd ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Marker_key
and not exists (select 1 from ${RADARDB}..WRK_LLRatLLIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ${RADARDB}..WRK_LLRatRGDIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
go

set nocount off
go

print ""
print "Bucket 8: MGD Rat Symbols with no LL ID, no RGD ID, but with a RatMap ID (the No-No-Yes set)"
print ""

select f.symbol "MGD Rat Symbol", f.name "MGD Rat Name", f.accID "RatMap ID"
from #nonoyesset f
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}
