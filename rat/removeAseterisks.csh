#!/bin/csh -fx

#
# Remove asterisks from Rat symbols...
#
# Usage:  LLremoveAsterisks.sh
#
# History
#	03/02/2001 lec
#	- TR 2265
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}

use ${DBNAME}
go

declare mrk_cursor cursor for
select _Marker_key, symbol
from MRK_Marker m1
where _Organism_key = 40 and symbol like '*%'
and not exists (select 1 from MRK_Marker m2
where m2._Organism_key = 40 and m2.symbol = substring(m1.symbol, 2, char_length(m1.symbol) - 2))
for read only
go

declare @markerKey integer
declare @symbol varchar(30)

open mrk_cursor
fetch mrk_cursor into @markerKey, @symbol

while (@@sqlstatus = 0)
begin
	update MRK_Marker
	set symbol = substring(@symbol, 2, char_length(@symbol) - 2)
	from MRK_Marker 
	where _Marker_key = @markerKey

	fetch mrk_cursor into @markerKey, @symbol
end

close mrk_cursor
deallocate cursor mrk_cursor
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
