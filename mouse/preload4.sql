#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 4 - MGI Acc ID Match; EntrezGene has no SeqID; MGI has no SeqID */

print ""
print "Bucket 4 - MGI Acc ID Match; EntrezGene has no SeqID; MGI has no SeqID; not in Bucket 1,2,3"
print ""

select distinct e1.geneID "EntrezGene ID", m.symbol "MGI Symbol", e1.compareID "MGI Acc ID"
from ${RADARDB}..WRK_EntrezGene_EGSet e1, ACC_Accession a, MRK_Marker m
where e1.idType = 'MGI'
and exists (select 1 from ${RADARDB}..WRK_EntrezGene_MGISet e where e1.compareID = e.mgiID)
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_EGSet e where e1.geneID = e.geneID and e.idType = 'Gen' 
	and e.compareID not like 'NM%')
and not exists (select 1 from ${RADARDB}..WRK_EntrezGene_MGISet e where e1.compareID = e.mgiID and e.idType = 'Gen')
and e1.compareID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = m._Marker_key
order by m.symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

