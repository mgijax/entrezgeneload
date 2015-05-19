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

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}

CREATE TEMP TABLE toUpdate
as select *
from WRK_EntrezGene_Nomen
where taxID = ${TAXID}
;

create index idx1 on toUpdate(_Marker_key)
;

update MRK_Marker
set symbol = egSymbol, name = egName, _ModifiedBy_key = 1001, modification_date = current_date
from toUpdate u, MRK_Marker m
where u._Marker_key = m._Marker_key
;

select * from toUpdate order by geneID
;

EOSQL
 
date >> ${LOG}
