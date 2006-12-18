#!/bin/csh -fx

#
# Program:
#	updateIDs.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Update all MGI Human/Rat EntrezGene ids to their 
#	"preferred" values using the EntrezGene history file.
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

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: updating EntrezGene ids..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh ${MGD_DBSERVER} ${MGD_DBNAME} $0 >>& ${LOG}
 
use ${MGD_DBNAME}
go

/* existing EntrezGene ids that are obsolete and need to be mapped to current ids */
/* only if the "new" EntrezGene id does not already exist */

select a._Accession_key, e.geneID
into #toupdate
from ACC_Accession a, ${RADAR_DBNAME}..DP_EntrezGene_History e
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID in (${HUMANTAXID}, ${RATTAXID}, ${DOGTAXID}, ${CHIMPTAXID})
and e.geneID != '-'
and not exists (select 1 from ACC_Accession x 
where x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
and x.accID = e.geneID)
go

create index idx1 on #toupdate(_Accession_key)
go

update ACC_Accession
set accID = u.geneID, numericPart = convert(integer, u.geneID)
from #toupdate u, ACC_Accession a
where u._Accession_key = a._Accession_key
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: updating EntrezGene ids." >> ${LOG}
