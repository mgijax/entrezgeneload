#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 9 - EntrezGene records from Bucket 0 with non-mRNA Seq IDs which are not associated with the */
/* corresponding MGI Marker. That is, those Seq IDs that were not added as part of the */
/* EntrezGene load because they are of genomic or undefined sequence type. */

print ""
print "Bucket 9 - EntrezGene records from Bucket 0 with non-mRNA SeqIDs not in MGI"
print ""
print "     EntrezGene records from Bucket 0 with non-mRNA Seq IDs which are not"
print "     associated with the corresponding MGI Marker. That is, those "
print "     Seq IDs that were not added as part of the load because they are genomic."
print ""

select e.accID "EntrezGene ID", ea.genomic "EntrezGene Seq ID"
from ${RADARDB}..WRK_EntrezGene_Bucket0 e, ${RADARDB}..DP_EntrezGene_Accession ea, ACC_Accession a
where e._LogicalDB_key = ${LOGICALEGKEY}
and e.accID = ea.geneID
and ea.genomic != '-'
and e.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and not exists (select 1 from ACC_Accession ma
where ea.genomic = ma.accID
and ma._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = ma._Object_key)
order by e.accID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

