#!/bin/csh -fx

#
# Process Human Updates
#
#	Update MGD Human symbols.
#
# 	   Editors add human symbols to MGD when homology
# 	   (ortholog) data is entered.  Once the human symbol
# 	   record exists in MGD, it will be updated by this
# 	   program.
#
# 	   Update the MGD Human record with the LL symbol 
#     	   information if the symbol/name LL info != MGD data
#     	   by doing a lookup by LL ID.
#
#     	   The chromosome and cytogenetic info is updated
#     	   by the 'gdbload' product.  See TR 1364 for details.
#
# Usage:  LLupdate.sh
#
# History
#	03/02/2001 lec
#	- TR 2265
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}

use ${DBNAME}
go

/* update MGD symbols from LL using LL ID */

declare mrk_cursor1 cursor for
select _Marker_key, symbol, name, osymbol, lname
from ${RADARDB}..WRK_LLHumanNomenUpdates
for read only
go

set nocount on
go

declare @markerKey integer
declare @newmarkerKey integer
declare @msymbol varchar(30)
declare @osymbol varchar(30)
declare @mname varchar(255)
declare @lname varchar(255)

open mrk_cursor1
fetch mrk_cursor1 into @markerKey, @msymbol, @mname, @osymbol, @lname

while (@@sqlstatus = 0)
begin
	/* Nomenclature event if MGD symbol != LL Official Symbol */
	/* AND LL Official Symbol already exists in MGD */

	if @msymbol != @osymbol and 
	   exists (select _Marker_key from MRK_Marker 
		where _Organism_key = ${HUMANSPECIESKEY} and symbol = @osymbol)
	begin
		/* Get marker key of LL Official Symbol */
		select @newmarkerKey = _Marker_key from MRK_Marker
			where _Organism_key = ${HUMANSPECIESKEY} and symbol = @osymbol

		/* Update Homology records */
		exec HMD_nomenUpdate @markerKey, @newmarkerKey

		/* Re-set @markerKey to marker key of LL Official symbol */
		select @markerKey = @newmarkerKey
	end

	print "Updating...%1! to %2!", @msymbol, @osymbol
	print "Updating...%1! to %2!", @mname, @lname
	update MRK_Marker
	set symbol = @osymbol, 
	name = @lname, 
	modification_date = getdate()
	where _Marker_key = @markerKey

	fetch mrk_cursor1 into @markerKey, @msymbol, @mname, @osymbol, @lname
end

close mrk_cursor1
deallocate cursor mrk_cursor1
go

/* update MGD chromosome/offset from LL using LL ID */

declare mrk_cursor2 cursor for
select _Marker_key, llChr, llOff
from ${RADARDB}..WRK_LLHumanMappingUpdates
for read only
go

declare @markerKey integer
declare @lchr varchar(15)
declare @loff varchar(100)

open mrk_cursor2
fetch mrk_cursor2 into @markerKey, @lchr, @loff

while (@@sqlstatus = 0)
begin
	update MRK_Marker
	set chromosome = @lchr, 
	cytogeneticOffset = @loff,
	modification_date = getdate()
	where _Marker_key = @markerKey

	fetch mrk_cursor2 into @markerKey, @lchr, @loff
end

close mrk_cursor2
deallocate cursor mrk_cursor2
go

set nocount off
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
