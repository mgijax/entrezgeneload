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

select e.accID "Seq ID", e.geneID "EntrezGene ID", m.symbol "MGI Symbol/Clone", a.accID "MGI Acc ID"
from ${RADARDB}..WRK_LLExcludeSeqIDs e, MRK_Marker m, ACC_Accession a
where e._MGIType_key = ${MARKERTYPEKEY}
and e._Object_key = m._Marker_key
and e._Object_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a.prefixPart = "MGI:"
and a._LogicalDB_key = 1
and a.preferred = 1
union
select e.accID, e.geneID, p.name, a.accID
from ${RADARDB}..WRK_LLExcludeSeqIDs e, PRB_Probe p, ACC_Accession a
where e._MGIType_key = ${PROBETYPEKEY}
and e._Object_key = p._Probe_key
and e._Object_key = a._Object_key
and a._MGIType_key = ${PROBETYPEKEY}
and a.prefixPart = "MGI:"
and a._LogicalDB_key = 1
and a.preferred = 1
order by e.accID, a.accID
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

