#!/bin/csh
 
isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> $1

use ${MGD_DBNAME}
go

set nocount on
go

/* remove duplicate markers by tax id */

select oldKey = a._Object_key, e.oldgeneID, e.geneID, newKey = x._Object_key
into #todelete
from ACC_Accession a, ${RADAR_DBNAME}..DP_EntrezGene_History e, ACC_Accession x
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID = ${TAXID}
and e.geneID != '-'
and e.geneID = x.accID
and x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
and exists (select 1 from HMD_Homology_Marker hm where a._Object_key = hm._Marker_key)
order by oldKey
go

create index idx1 on #todelete(oldKey)
create index idx2 on #todelete(newKey)
go

select geneKey = d.newKey, d.geneID, m1.symbol, mouseSymbol = m2.symbol, h1._Class_key, h1._Refs_key
into #orthologs
from #todelete d, MRK_Marker m1, MRK_Homology_Cache h1, MRK_Homology_Cache h2, MRK_Marker m2
where d.newKey = m1._Marker_key
and d.newKey = h1._Marker_key
and h1._Homology_key = h2._Homology_key
and h2._Organism_key = 1
and h2._Marker_key = m2._Marker_key
union
select d.oldKey, d.oldgeneID, m1.symbol, mouseSymbol = m2.symbol, h1._Class_key, h1._Refs_key
from #todelete d, MRK_Marker m1, MRK_Homology_Cache h1, MRK_Homology_Cache h2, MRK_Marker m2
where d.oldKey = m1._Marker_key
and d.oldKey = h1._Marker_key
and h1._Homology_key = h2._Homology_key
and h2._Organism_key = 1
and h2._Marker_key = m2._Marker_key
go

create index idx1 on #orthologs(geneKey)
create index idx2 on #orthologs(_Refs_key)
go

set nocount off
go

print ""
print "Bucket 6: Human Markers that need to be merged in MGI that also have Orthology Data"
print ""

select substring(o.geneID,1,10) "EG ID", m.symbol "Symbol", o._Class_key, jnum = a.accID
from #todelete d, #orthologs o, MRK_Marker m, ACC_Accession a
where d.oldKey = o.geneKey
and d.oldKey = m._Marker_key
and o._Refs_key = a._Object_key
and a._MGIType_key = 1
and a.prefixPart = "J:"
union
select substring(o.geneID,1,10) "EG ID", m.symbol "Symbol", o._Class_key, jnum = a.accID
from #todelete d, #orthologs o, MRK_Marker m, ACC_Accession a
where d.newKey = o.geneKey
and d.newKey = m._Marker_key
and o._Refs_key = a._Object_key
and a._MGIType_key = 1
and a.prefixPart = "J:"
go

quit

END

