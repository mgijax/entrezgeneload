#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	deleteOrphans.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	To delete orphans (those markers not involved
#	in any orthology) for given Organism
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
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv DATADIR $1
setenv ORGANISM $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting orphan markers..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

declare mrk_cursor cursor for
select _Marker_key
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select h.* from HMD_Homology_Marker h where m._Marker_key = h._Marker_key)
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
