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

select distinct l.geneID, l.locusTag, l.symbol
into #nomatch
from ${RADARDB}..DP_EntrezGene_Info l
where l.taxID = ${MOUSETAXID}
and l.locusTag is not null
and not exists (select 1 from ACC_Accession a
where l.locusTag = a.accID
and a._MGIType_key = ${MARKERTYPEKEY})
go

set nocount off
go

print ""
print "Bucket 8 - EntrezGene records with no MGI Acc ID match"
print ""

select m.geneID "EntrezGene ID", m.locusTag "EntrezGene MGI Acc ID", m.symbol "EntrezGene Symbol", a.genbankID
from #nomatch m, ${RADARDB}..DP_LLAcc a
where m.geneID *= a.geneID
order by geneID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

