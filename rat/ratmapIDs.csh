#!/bin/csh -fx

#
# Attach RatMap IDs to Symbols which do not have one
#
# Usage:  LLratmapIDs.sh
#
# History
#
#	08/26/2003 lec
#	- TR 4342
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}

use ${DBNAME}
go

/* add the RatMap id to all rat markers which do not have one */

declare acc_cursor cursor for
select *
from ${RADARDB}..WRK_LLRatRATMAPIDsToAdd
for read only
go

declare @markerKey integer
declare @ratmapID varchar(30)

open acc_cursor
fetch acc_cursor into @markerKey, @ratmapID

while (@@sqlstatus = 0)
begin
	exec ACC_insert @markerKey, @ratmapID, ${LOGICALRATMAPKEY}, 'Marker', -1, 1, ${RATMAPPRIVATE}
	fetch acc_cursor into @markerKey, @ratmapID
end

close acc_cursor
deallocate cursor acc_cursor
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
