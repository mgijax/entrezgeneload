#!/bin/csh
 
source ../Configuration
setenv OUTPUTFILE	$1
setenv REPORTFILE	${OUTPUTFILE}.rpt

${REPORTHEADER} ${OUTPUTFILE}

isql -S${DBSERVER} -U${PUBDBUSER} -P${PUBDBPASSWORD} -w300 <<END >> ${REPORTFILE}

use ${DBNAME}
go

print ""
print "Bucket 2: MGD Rat Symbols without a LL ID but with a RGD ID (the No-Yes set)"
print ""
print "     Records which are in the duplicates file are ignored during processing."
print ""

select m.symbol, rgdID = ma.accID, in_duplicates_file = "yes"
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY}
and not exists (select 1 from ${RADARDB}..WRK_LLRatLLIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates l
where ma.accID = l.gsdbID)
union
select m.symbol, rgdID = ma.accID, in_duplicates_file = "no"
from MRK_Marker m, ACC_Accession ma
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALRGDKEY}
and not exists (select 1 from ${RADARDB}..WRK_LLRatLLIDsToAdd l
where m._Marker_key = l._Marker_key)
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates l
where ma.accID = l.gsdbID)
order by in_duplicates_file desc, symbol
go

quit

END

cat ${REPORTTRAILER} >> ${REPORTFILE}

