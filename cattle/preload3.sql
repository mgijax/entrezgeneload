#!/bin/csh -f
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

print ""
print "Bucket 3: MGI Cattle Symbols with an invalid EntrezGene ID or no EntrezGene ID"
print ""

select m.symbol, a.accID
from MRK_Marker m, ACC_Accession a
where m._Organism_key = ${ORGANISM}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and not exists (select 1 from ${RADAR_DBNAME}..DP_EntrezGene_Info e
	where e.taxID = ${TAXID}
	      and a.accID = e.geneID)
union
select m.symbol, accID = NULL
from MRK_Marker m 
where m._Organism_key = ${ORGANISM}
and not exists (select 1 from ACC_Accession a 
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY})
order by a.accID, m.symbol
go

quit

END

