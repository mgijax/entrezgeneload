#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

/* Bucket 2 - EntrezGene IDs/Seq IDs w/ > 1 MGI Marker Match */

print ""
print "Bucket 2 - Seq IDs which map to > 1 MGI Marker + Problem Clones"
print ""
print "     Seq IDs which are excluded from processing because they are: "
print "     a) associated with more than one MGI Marker OR"
print "     b) associated with a Probe which contains a Problem Note and "
print "        is associated with > 1 Seq ID."
print ""

select e.seqID "Seq ID", e.geneID "EntrezGene ID", m.symbol "MGI Symbol/Clone", e.mgiID "MGI Acc ID"
from ${RADARDB}..WRK_EntrezGene_ExcludeB e, ACC_Accession a, MRK_Marker m
where e.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = m._Marker_key
union
select e.seqID, e.geneID, substring(p.name,1,50), e.mgiID "MGI Acc ID"
from ${RADARDB}..WRK_EntrezGene_ExcludeB e, ACC_Accession a, PRB_Probe p
where e.mgiID = a.accID
and a._MGIType_key = ${PROBETYPEKEY}
and a._Object_key = p._Probe_key
order by e.seqID, e.mgiID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

