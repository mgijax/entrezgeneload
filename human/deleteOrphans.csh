#!/bin/csh -fx

#
# Delete orphan Human Marker entries
#
# Usage:  deleteOrphans.csh
#
# History
#	

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting orphan Human markers..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

declare mrk_cursor cursor for
select _Marker_key
from MRK_Marker m
where m._Organism_key = ${HUMANSPECIESKEY}
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
echo "End: deleting orphan Human markers." >> ${LOG}
