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

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}

CREATE TEMP TABLE toUpdate
as select _Marker_key, egChr, egMapPosition
from WRK_EntrezGene_Mapping
where taxID = ${TAXID}
;

create index idx1 on toUpdate(_Marker_key)
;

update MRK_Marker
set chromosome = u.egChr,
    cytogeneticOffset = u.egMapPosition,
    _ModifiedBy_key = 1001,
    modification_date = current_date
from toUpdate u, MRK_Marker m
where u._Marker_key = m._Marker_key
;

select * from toUpdate
;

EOSQL
 
date >> ${LOG}
