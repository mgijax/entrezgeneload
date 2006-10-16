#!/bin/csh -fx

#
# Program:
#	updateMapping.csh
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

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date | tee -a ${LOG}

cat - <<EOSQL | doisql.csh ${MGD_DBSERVER} ${MGD_DBNAME} $0 | tee -a ${LOG}

use ${MGD_DBNAME}
go

declare mapping_cursor cursor for
select _Marker_key, egChr, egMapPosition
from ${RADAR_DBNAME}..WRK_EntrezGene_Mapping
where taxID = ${TAXID}
for read only
go

declare @markerKey integer
declare @echr varchar(15)
declare @emap varchar(100)

declare @userKey integer
select @userKey = _User_key from MGI_User where login = "${CREATEDBY}"

open mapping_cursor
fetch mapping_cursor into @markerKey, @echr, @emap

while (@@sqlstatus = 0)
begin
	update MRK_Marker
	    set chromosome = @echr, 
	        cytogeneticOffset = @emap,
		_ModifiedBy_key = @userKey,
	        modification_date = getdate()
	where _Marker_key = @markerKey

	fetch mapping_cursor into @markerKey, @echr, @emap
end

close mapping_cursor
deallocate cursor mapping_cursor
go

checkpoint
go

quit
 
EOSQL
 
date | tee -a ${LOG}
