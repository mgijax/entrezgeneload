#!/bin/csh -fx


# $HEADER$
# $NAME$

#
# Program:
#	updateIDs.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Update all MGI EntrezGene ids to their "preferred" values
#	using the EntrezGene history file.
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
# 01/03/2004 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: updating EntrezGene ids..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

/* existing EntrezGene ids that are obsolete and need to be mapped to current ids */

select a._Accession_key, e.geneID
into #toupdate
from ACC_Accession a, ${RADARDB}..DP_EntrezGene_History e
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID in (${HUMANTAXID}, ${RATTAXID})
and e.geneID != '-'
go

create index idx1 on #toupdate(_Accession_key)
go

update ACC_Accession
set accID = u.geneID
from #toupdate u, ACC_Accession a
where u._Accession_key = a._Accession_key
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: updating EntrezGene ids." >> ${LOG}
