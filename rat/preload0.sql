#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 0: Nomenclature Updates Processed"
print ""
print "     MGD Rat Symbols/Names which required nomenclature"
print "     updates based on a LL ID match between MGD and LL."
print "     The MGD Rat Symbol/Name has been updated to the LL Symbol/Name."
print ""

select distinct l.symbol "MGD Symbol", substring(l.name,1,50) "MGD Name", 
l.osymbol "LL Symbol", l.type "T", m2.symbol "Mouse Ortholog", substring(l.lname,1,50) "LL Name"
from ${RADARDB}..WRK_LLRatNomenUpdates l, MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
where l.osymbol = m1.symbol
and m1._Organism_key = ${RATSPECIESKEY}
and m1._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Class_key = h2._Class_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m2._Marker_key
and m2._Organism_key = ${MOUSESPECIESKEY}
union
select distinct l.symbol "MGD Symbol", substring(l.name,1,50) "MGD Name", 
l.osymbol "LL Symbol", l.type "T", null, substring(l.lname,1,50) "LL Name"
from ${RADARDB}..WRK_LLRatNomenUpdates l
where not exists (select 1 from MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
where l.osymbol = m1.symbol
and m1._Organism_key = ${RATSPECIESKEY}
and m1._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Class_key = h2._Class_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m2._Marker_key
and m2._Organism_key = ${MOUSESPECIESKEY})
order by l.symbol
go

print ""
print "Bucket 0: New LL IDs Attached"
print ""
print "     If the LL record also contains a RGD ID or RatMap ID, then that "
print "     ID will also be attached."
print ""

select locusID "LL ID", osymbol "LL Symbol", gsdbID "RGD ID", ratmapID "RatMap ID"
from ${RADARDB}..WRK_LLRatLLIDsToAdd
order by osymbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

