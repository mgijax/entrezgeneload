#!/bin/csh -fx

#
# Process Human Updates
#
# Usage:  LLload.sh
#
# History
#	03/02/2001 lec
#	- TR 2265
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

# create temp tables
LLcreateTempTables.sh >>& ${LOG}

# run pre-load reports
LLpreload.sh >>& ${LOG}

# process locuslink ids
LLIDs.sh >>& ${LOG}

# process rgd ids
LLrgdIDs.sh >>& ${LOG}

# process ratmap ids
LLratmapIDs.sh >>& ${LOG}

# update nomenclature
LLupdate.sh >>& ${LOG}

# run post-load reports
LLpostload.sh >>& ${LOG}

# update statistics
${DBUTILITIESPATH}/bin/updateStatistics.csh ${DBSERVER} ${DBNAME} ACC_Accession
${DBUTILITIESPATH}/bin/updateStatistics.csh ${DBSERVER} ${DBNAME} ACC_AccessionReference

date >> ${LOG}
