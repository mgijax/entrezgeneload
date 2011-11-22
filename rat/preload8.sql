#!/bin/csh -f
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

set nocount on
go

/* No-No-Yes Set */

select m._Marker_key, m.symbol, name = substring(m.name,1,30), ma.accID
into #nonoyesset
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${ORGANISM}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRATMAPKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALEGKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
go

set nocount off
go

print ""
print "Bucket 8: MGI Rat Symbols with no EG ID, no RGD ID, but with a RatMap ID (the No-No-Yes set)"
print ""

select f.symbol "MGI Rat Symbol", f.name "MGI Rat Name", f.accID "RatMap ID"
from #nonoyesset f
order by symbol
go

quit

END

