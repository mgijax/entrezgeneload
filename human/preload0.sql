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
print "     MGI Human Symbols/Names which required nomenclature"
print "     updates based on a EG ID match between MGI and EG."
print ""
print "     The MGI Human Symbol/Name has been updated to the EG Symbol/Name."
print ""

select distinct e.mgiSymbol "MGI Symbol", substring(e.mgiName,1,50) "MGI Name", 
       e.egSymbol "EG Symbol", m2.symbol "Mouse Ortholog", substring(e.egName,1,50) "EG Name"
from ${RADARDB}..WRK_EntrezGene_Nomen e,
     MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
     MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
where e.taxID = ${HUMANTAXID}
and e._Marker_key = m1._Marker_key
and m1._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Class_key = h2._Class_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m2._Marker_key
and m2._Organism_key = ${MOUSESPECIESKEY}
union
select e.mgiSymbol "MGI Symbol", substring(e.mgiName,1,50) "MGI Name", 
       e.egSymbol "EG Symbol", null, substring(e.egName,1,50) "EG Name"
from ${RADARDB}..WRK_EntrezGene_Nomen e
where e.taxID = ${HUMANTAXID}
and not exists (select 1 from MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
                              MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
		where e._Marker_key = m1._Marker_key
		and m1._Marker_key = hm1._Marker_key
		and hm1._Homology_key = h1._Homology_key
		and h1._Class_key = h2._Class_key
		and h2._Homology_key = hm2._Homology_key
		and hm2._Marker_key = m2._Marker_key
		and m2._Organism_key = ${MOUSESPECIESKEY})
order by e.egSymbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

