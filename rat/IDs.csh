#!/bin/csh -fx

#
# Attach LocusLink IDs to Symbols which do not have one
#
# Usage:  LLIDs.sh
#
# History
#
#	08/26/2003	lec
#	- TR 4342
#

cd `dirname $0` && source ../Configuration

setenv LOG      $RATDATADIR/`basename $0`.log
rm -rf $LOG
touch $LOG

date >> $LOG

cat - <<EOSQL | doisql.csh $0 >>& $LOG

use $DBNAME
go

/* add the LL id to all rat markers which do not have one */

set nocount on
go

declare acc_cursor cursor for
select _Marker_key, locusID
from ${RADARDB}..WRK_LLRatLLIDsToAdd
for read only
go

declare @markerKey integer
declare @accID varchar(30)

open acc_cursor
fetch acc_cursor into @markerKey, @accID

while (@@sqlstatus = 0)
begin
	exec ACC_insert @markerKey, @accID, $LOGICALLLKEY, 'Marker', -1, 1, $RATLLPRIVATE
	fetch acc_cursor into @markerKey, @accID
end

close acc_cursor
deallocate cursor acc_cursor
go

checkpoint
go

set nocount off
go

quit
 
EOSQL
 
date >> $LOG
