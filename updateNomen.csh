#!/bin/csh -f

#
# Program:
#	updateNomen.csh
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

select *
into #toupdate
from ${RADAR_DBNAME}..WRK_EntrezGene_Nomen
where taxID = ${TAXID}
go

create index idx1 on #toupdate(_Marker_key)
go

declare @userKey integer
select @userKey = _User_key from MGI_User where login = "${CREATEDBY}"

update MRK_Marker
set symbol = egSymbol, name = egName, _ModifiedBy_key = @userKey, modification_date = getdate()
from #toupdate u, MRK_Marker m
where u._Marker_key = m._Marker_key
go

select * from #toupdate order by geneID
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
