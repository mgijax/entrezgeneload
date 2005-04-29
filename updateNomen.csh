#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	updateNomen.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
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

setenv DATADIR  $1
setenv TAXID	$2
setenv ORGANISM $3

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}

use ${DBNAME}
go

declare nomen_cursor cursor for
select _Marker_key, mgiSymbol, mgiName, egSymbol, egName
from ${RADARDB}..WRK_EntrezGene_Nomen
where taxID = ${TAXID}
for read only
go

declare @markerKey integer
declare @newmarkerKey integer
declare @msymbol varchar(50)
declare @esymbol varchar(50)
declare @mname varchar(255)
declare @ename varchar(255)

declare @userKey integer
select @userKey = _User_key from MGI_User where login = "${CREATEDBY}"

open nomen_cursor
fetch nomen_cursor into @markerKey, @msymbol, @mname, @esymbol, @ename

while (@@sqlstatus = 0)
begin
	/* Nomenclature event if MGI symbol != EG Symbol and EG Symbol already exists in MGI */

	if @msymbol != @esymbol and 
	   exists (select _Marker_key from MRK_Marker 
		where _Organism_key = ${ORGANISM} and symbol = @esymbol)
	begin
		/* Get marker key of EG Symbol */
		select @newmarkerKey = _Marker_key from MRK_Marker
			where _Organism_key = ${ORGANISM} and symbol = @esymbol

		/* Update Orthology records */
		exec HMD_nomenUpdate @markerKey, @newmarkerKey

		/* Re-set @markerKey to marker key of EG symbol */
		select @markerKey = @newmarkerKey
	end

	print "Updating...%1! to %2!", @msymbol, @esymbol
	print "Updating...%1! to %2!", @mname, @ename

	update MRK_Marker
	    set symbol = @esymbol, 
		name = @ename, 
		_ModifiedBy_key = @userKey,
		modification_date = getdate()
	    where _Marker_key = @markerKey

	fetch nomen_cursor into @markerKey, @msymbol, @mname, @esymbol, @ename
end

close nomen_cursor
deallocate cursor nomen_cursor
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
