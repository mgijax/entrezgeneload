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
print "     Seq IDs that were not added as part of the load because they are "
print "     of genomic or undefined sequence type."
print ""

select distinct l.llaccID "EntrezGene ID", a.genbankID "EntrezGene Seq ID", a.seqType
from ${RADARDB}..WRK_LLBucket0 l, ${RADARDB}..DP_LLAcc a
where l.llaccID = a.geneID
and a.genbankID not like 'NM%'
and a.seqType != 'm'
and not exists (select 1 from ACC_Accession ma
where a.genbankID = ma.accID
and ma._MGIType_key = ${MARKERTYPEKEY})
order by l.llaccID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

