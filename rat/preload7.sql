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

/* No-No-No Set */

select m._Marker_key, symbol = substring(m.symbol,1,30), name = substring(m.name,1,30)
into #nonoset
from MRK_Marker m
where m._Organism_key = ${RATSPECIESKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALEGKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRATMAPKEY})
go

/* Get records that have a match to EG Symbols */

select m.*, e.geneID, e.locusTag,
egsymbol = substring(e.symbol,1,30), egname = substring(e.name,1,30)
into #match
from #nonoset m, ${RADARDB}..DP_EntrezGene_Info e
where e.taxid = ${RATTAXID}
and m.symbol = e.symbol
go

/* Get Ref Seq IDs for any matched symbols that have them */

select m.*, r.rna
into #refSeq
from #match m, ${RADARDB}..DP_EntrezGene_RefSeq r
where m.geneID = r.geneID
and r.rna like 'NM%'
union
select m.*, NULL
from #match m
where not exists (select 1 from ${RADARDB}..DP_EntrezGene_RefSeq r
where m.geneID = r.geneID
and r.rna like 'NM%')
go

select *
into #final
from #refSeq
union
select n.*, NULL, NULL, NULL, NULL, NULL
from #nonoset n
where not exists (select 1 from #refSeq m
where n._Marker_key = m._Marker_key)
set nocount off
go

print ""
print "Bucket 7: MGI Rat Symbols with no EG ID, no RGD ID, no RatMap ID (the No-No-No set)"
print ""
print "     a.  Displays any matches between MGI and EG by EG Symbol"
print "     b.  Displays Mouse Symbol/Name if a Mouse/Rat Homology exists based on the EG Symbol match."
print ""


select f.symbol "MGI Rat Symbol", f.name "MGI Rat Name", 
f.egsymbol "EG Symbol", f.egname "EG Name", f.locusTag "EG RGD ID", f.geneID "EG ID",
f.rna "EG RefSeq ID",
m.symbol "Mouse Symbol", 
substring(m.name, 1, 30) "Mouse Name"
from #final f, HMD_Homology h1, HMD_Homology_Marker hm1, 
HMD_Homology h2, HMD_Homology_Marker hm2, MRK_Marker m
where f._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Homology_key = h2._Homology_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m._Marker_key
and m._Organism_key = ${MOUSESPECIESKEY}
union
select f.symbol, f.name, f.egsymbol, f.egname, f.locusTag, f.geneID, f.rna, NULL, NULL
from #final f
where not exists (select 1 from
HMD_Homology h1, HMD_Homology_Marker hm1, HMD_Homology h2, HMD_Homology_Marker hm2, MRK_Marker m
where f._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Homology_key = h2._Homology_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m._Marker_key
and m._Organism_key = ${MOUSESPECIESKEY})
order by symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}
