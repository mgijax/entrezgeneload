#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go


print ""
print "Bucket 6: MGD Human Symbols with an obsolete LL ID"
print ""

select m.symbol, llid = a.accID, genbankID = a2.accID
from ACC_Accession a, MRK_Marker m, ACC_Accession a2
where m._Organism_key = 2
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALLLKEY}
and not exists (select 1 from ${RADARDB}..DP_LL l
where a.accID = l.locusID
and l.taxid = ${HUMANTAXID})
and m._Marker_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = ${LOGICALSEQKEY}
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

