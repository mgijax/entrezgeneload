#!/bin/csh -fx

#
# Process Mouse
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

./deleteExistingEntries.csh
./createExclude.csh
./createSets.csh
./createBuckets.csh
../runreports.csh ${MOUSEDATADIR} ${MOUSEARCHIVEDIR}
../accids.py -O${MOUSEDATADIR} -T${MOUSETAXID}
#cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${MOUSEDATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}
#cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${MOUSEDATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}

date >> ${LOG}
