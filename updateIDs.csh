#!/bin/csh -f

#
# Program:
#	updateIDs.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Update all MGI non-mouse EntrezGene ids to their 
#	"preferred" values using the EntrezGene history file.
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

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: updating EntrezGene ids..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
/* existing EntrezGene ids that are obsolete and need to be mapped to current ids */
/* only if the "new" EntrezGene id does not already exist */
/* we don't want to create duplicate entries */
/* see deleteIDs.csh for handling of potential duplicates */

CREATE TEMP TABLE toUpdate 
as select a._Accession_key, e.geneID
from ACC_Accession a, DP_EntrezGene_History e
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID in (${HUMANTAXID}, ${RATTAXID}, ${DOGTAXID}, ${CHIMPTAXID}, ${CATTLETAXID}, ${CHICKENTAXID}, ${ZEBRAFISHTAXID}, ${MONKEYTAXID}, ${XENOPUSTAXID})
and e.geneID != '-'
and not exists (select 1 from ACC_Accession x 
where x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
and x.accID = e.geneID)
;

create index idx1 on toUpdate(_Accession_key)
;

update ACC_Accession a
set accID = u.geneID, numericPart = u.geneID::INTEGER
from toUpdate u
where u._Accession_key = a._Accession_key
;

EOSQL
 
date >> ${LOG}
echo "End: updating EntrezGene ids." >> ${LOG}

