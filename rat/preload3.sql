#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 3: MGI Rat Symbols with an obsolete EntrezGene ID"
print ""

select m.symbol, a.accID
from MRK_Marker m, ACC_Accession a
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and not exists (select 1 from ${RADARDB}..DP_EntrezGene_Info e
	where e.taxID = ${RATTAXID}
	      and a.accID = e.geneID)
order by m.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

