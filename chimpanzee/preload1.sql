#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${REPORTFILE}

isql -S${MGD_DBSERVER} -U${MGI_PUBLICUSER} -P${MGI_PUBLICPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${MGD_DBNAME}
go

print ""
print "Bucket 1: Mapping Updates Processed"
print ""
print "     MGI Chimpanzee Chromosomes and/or Mapping positions that required"
print "     updates based on a EG ID match between MGI and EG."
print ""

select distinct e.geneID "EG ID", substring(m.symbol,1,25) "Symbol", 
       e.mgiChr "MGI chromosome", e.mgiMapPosition "MGI Map Position",
       e.egChr "EG chromosome", substring(e.egMapPosition,1,20) "EG Map Position"
from ${RADAR_DBNAME}..WRK_EntrezGene_Mapping e, MRK_Marker m
where e.taxID = ${CHIMPTAXID}
and e._Marker_key = m._Marker_key
order by e.geneID
go

quit

END

