#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 8 - EntrezGene records with no MGI Acc ID match. */

set nocount on
go

select distinct e.geneID, e.compareID, i.symbol
into #nomatch
from ${RADARDB}..WRK_EntrezGene_EGSet e, ${RADARDB}..DP_EntrezGene_Info i
where e1.taxID = ${MOUSETAXID}
and e.idType = 'MGI'
and not exists (select 1 from ACC_Accession m 
	where m._MGIType_key = ${MARKERTYPEKEY} 
	and e.compareID = m.accID)
and e.geneID = i.geneID
go

set nocount off
go

print ""
print "Bucket 8 - EntrezGene records with no MGI Acc ID match"
print ""

select m.geneID "EntrezGene ID", m.compareID "EntrezGene MGI Acc ID", m.symbol "EntrezGene Symbol", a.rna
from #nomatch m, ${RADARDB}..DP_EntrezGene_Accession a
where m.geneID *= a.geneID
order by geneID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

