#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 1: Mapping Updates Processed"
print ""
print "     MGI Human Chromosomes and/or Mapping positions that required"
print "     updates based on a EG ID match between MGI and EG."
print ""

select distinct e.geneID "EG ID", e.egSymbol "Symbol", 
       e.mgiChr "MGI chromosome", e.mgiMapPosition "MGI Map Position",
       e.egChr "EG chromosome", e.egMapPosition "EG Map Position"
from ${RADARDB}..WRK_EntrezGene_Mapping e
where e.taxID = ${HUMANTAXID}
order by e.geneID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

