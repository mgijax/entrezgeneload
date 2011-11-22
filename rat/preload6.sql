#!/bin/csh -f
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

set nocount on
go

select symbol
into #duplicates
from MRK_Marker
where _Organism_key = ${ORGANISM}
group by symbol having count(*) > 1
go

create index idx1 on #duplicates(symbol)
go

set nocount off
go

print ""
print "Bucket 6: MGI Rat Symbols without a EG ID but with a RGD ID (the No-Yes set)"
print ""

select m.symbol, rgdID = ma.accID, in_duplicates_file = "yes"
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${ORGANISM}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALEGKEY})
and exists (select 1 from #duplicates d where m.symbol = d.symbol)
union
select m.symbol, rgdID = ma.accID, in_duplicates_file = "no"
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${ORGANISM}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALEGKEY})
and not exists (select 1 from #duplicates d where m.symbol = d.symbol)
order by in_duplicates_file desc, symbol
go

quit

END

