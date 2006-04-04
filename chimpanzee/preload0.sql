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

select distinct mgiSymbol = substring(e.mgiSymbol,1,25), 
       mgiName = substring(e.mgiName,1,50), 
       egSymbol = substring(e.egSymbol,1,25), 
       symbol = substring(m2.symbol,1,25), 
       egName = substring(e.egName,1,50)
into #results
from ${RADAR_DBNAME}..WRK_EntrezGene_Nomen e,
     MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
     MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
where e.taxID = ${CHIMPTAXID}
and e._Marker_key = m1._Marker_key
and m1._Marker_key = hm1._Marker_key
and hm1._Homology_key = h1._Homology_key
and h1._Class_key = h2._Class_key
and h2._Homology_key = hm2._Homology_key
and hm2._Marker_key = m2._Marker_key
and m2._Organism_key = ${MOUSESPECIESKEY}
union
select substring(e.mgiSymbol,1,25), 
       substring(e.mgiName,1,50),
       substring(e.egSymbol,1,25), 
       null, 
       substring(e.egName,1,50)
from ${RADAR_DBNAME}..WRK_EntrezGene_Nomen e
where e.taxID = ${CHIMPTAXID}
and not exists (select 1 from MRK_Marker m1, HMD_Homology_Marker hm1, HMD_Homology h1,
                              MRK_Marker m2, HMD_Homology_Marker hm2, HMD_Homology h2
		where e._Marker_key = m1._Marker_key
		and m1._Marker_key = hm1._Marker_key
		and hm1._Homology_key = h1._Homology_key
		and h1._Class_key = h2._Class_key
		and h2._Homology_key = hm2._Homology_key
		and hm2._Marker_key = m2._Marker_key
		and m2._Organism_key = ${MOUSESPECIESKEY})
go

set nocount off
go

print ""
print "Bucket 0: Nomenclature Updates Processed"
print ""
print "     MGI Chimpanzee Symbols/Names which required nomenclature"
print "     updates based on a EG ID match between MGI and EG."
print ""
print "     The MGI Chimpanzee Symbol/Name has been updated to the EG Symbol/Name."
print ""

select mgiSymbol "MGI Symbol", mgiName "MGI Name", egSymbol "EG Symbol", symbol "Mouse Ortholog", egName "EG Name"
from #results
order by egSymbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

