#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 5: New Human Markers Added to MGI"
print ""

select b.accID "EG ID", e.symbol "Symbol", e.name "Name", e.chromosome "Chromosome", e.mapPosition "Map Position"
from ${RADARDB}..WRK_EntrezGene_Bucket0 b, ${RADARDB}..DP_EntrezGene_Info e
where b.taxID = ${HUMANTAXID}
and b._Object_key = -1
and b._LogicalDB_key = ${LOGICALEGKEY}
and b.accID = e.geneID
order by e.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}
