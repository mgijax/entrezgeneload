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

/* No-No Set */

select m._Marker_key, m.symbol, name = substring(m.name,1,30)
into #nonoset
from MRK_Marker m
where m._Organism_key = 2
and not exists (select 1 from ${RADARDB}..WRK_LLHumanLLIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ${RADARDB}..WRK_LLHumanGDBIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALGDBKEY})
go

/* Get records that have a match to either LL Official or Interim Symbols */

select m.*, llsymbol = substring(l.osymbol,1,50), symType = "O", 
llname = substring(l.name,1,30), l.gsdbID, l.locusID
into #match
from #nonoset m, ${RADARDB}..DP_LL l
where m.symbol = l.osymbol
and l.taxid = ${HUMANTAXID}
union
select m.*, llsymbol = substring(l.isymbol,1,50), symType = "I", 
llname = substring(l.name,1,30), l.gsdbID, l.locusID
from #nonoset m, ${RADARDB}..DP_LL l
where m.symbol = l.isymbol
and l.taxid = ${HUMANTAXID}
go

/* Get Ref Seq IDs for any matched symbols that have them */

select m.*, r.refSeqID
into #refSeq
from #match m, ${RADARDB}..DP_LLRef r
where m.locusID = r.locusID
and r.refSeqID like 'NM%'
union
select m.*, NULL
from #match m
where not exists (select 1 from ${RADARDB}..DP_LLRef r 
where m.locusID = r.locusID
and r.refSeqID like 'NM%')
go

select *
into #final
from #refSeq
union
select n.*, NULL, NULL, NULL, NULL, NULL, NULL
from #nonoset n
where not exists (select 1 from #refSeq m
where n._Marker_key = m._Marker_key)
set nocount off
go

print ""
print "Bucket 1: MGD Human Symbols with neither a LL ID nor GDB ID (the No-No set)"
print ""
print "     a.  Displays any matches between MGD and LL by LL Official or Interim Symbol"
print "     b.  Displays Mouse Symbol/Name if a Mouse/Human Homology exists based"
print "         on the LL Official/Interim Symbol match."
print ""


select f.symbol "MGD Human Symbol", f.name "MGD Human Name", 
f.llsymbol "LL Symbol", f.symType "Type", f.llname "LL Name", f.gsdbID "LL GDB ID", f.locusID "LL ID",
f.refSeqID "LL RefSeq ID",
m.symbol "Mouse Symbol", 
substring(m.name, 1, 30) "Mouse Name"
from #final f, HMD_Homology h1, HMD_Homology_Marker hm1, 
HMD_Homology h2, HMD_Homology_Marker hm2, MRK_Marker m
where f._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Homology_key = h2._Homology_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m._Marker_key
and m._Organism_key = 1
union
select f.symbol, f.name, f.llsymbol, f.symType, f.llname, f.gsdbID, f.locusID, f.refSeqID, NULL, NULL
from #final f
where not exists (select 1 from
HMD_Homology h1, HMD_Homology_Marker hm1, HMD_Homology h2, HMD_Homology_Marker hm2, MRK_Marker m
where f._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Homology_key = h2._Homology_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m._Marker_key
and m._Organism_key = 1)
order by symType desc, symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

