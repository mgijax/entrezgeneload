#!/bin/csh -fx

#
# Program:
#	deleteObsolete.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	To delete orphan Marker records for given Organism
#
#	Delete Markers that have no Orthology AND
#	that have no counterpart in the EG info table (by EG id).
#
# Requirements Satisfied by This Program:
#
# Usage:
#
# Envvars:
#
# Inputs:
#
# Outputs:
#
# Exit Codes:
#
# Assumes:
#
# Bugs:
#
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 04/28/2005 - lec
#	- TR 3853, OMIM
#

setenv DATADIR $1
setenv TAXID $2
setenv ORGANISM $3

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting obsolete markers..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${MGD_DBNAME}
go

declare mrk_cursor cursor for
select m._Marker_key
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select h.* from HMD_Homology_Marker h where m._Marker_key = h._Marker_key)
and not exists (select e.* from ${RADAR_DBNAME}..DP_EntrezGene_Info e, ACC_Accession a
	where e.taxID = ${TAXID}
	and m._Marker_key = a._Object_key
	and a._MGIType_key = 2
	and a._LogicalDB_key = ${LOGICALEGKEY}
	and a.accID = e.geneID)
for read only
go

declare @markerKey integer

open mrk_cursor
fetch mrk_cursor into @markerKey

while (@@sqlstatus = 0)
begin
        delete MRK_Marker where _Marker_key = @markerKey
        fetch mrk_cursor into @markerKey
end

close mrk_cursor
deallocate cursor mrk_cursor
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: deleting orphan markers." >> ${LOG}
