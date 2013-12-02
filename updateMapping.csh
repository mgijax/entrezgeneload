#!/bin/csh -f

#
# Program:
#	updateMapping.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#
# Modification History:
#
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh ${MGD_DBSERVER} ${MGD_DBNAME} $0 >>& ${LOG}

use ${MGD_DBNAME}
go

select _Marker_key, egChr, egMapPosition
into #toUpdate
from ${RADAR_DBNAME}..WRK_EntrezGene_Mapping
where taxID = ${TAXID}
go

create index idx1 on #toUpdate(_Marker_key)
go

declare @userKey integer
select @userKey = _User_key from MGI_User where login = "${CREATEDBY}"

update MRK_Marker
set chromosome = u.egChr,
    cytogeneticOffset = u.egMapPosition,
    _ModifiedBy_key = @userKey,
    modification_date = getdate()
from #toUpdate u, MRK_Marker m
where u._Marker_key = m._Marker_key
go

select * from #toUpdate
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
