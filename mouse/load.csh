#!/bin/csh -fx

#
# Process Mouse LocusLink Load
#
# Usage:  LLload.sh
#
# History
#	01/03/2001 lec
#	- TR 1467 - adding mRNA Seq IDs
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: Mouse load..." >> ${LOG}
date >> ${LOG}

deleteExistingEntries.csh
createExclude.csh
createSets.csh
createBuckets.csh
preload.csh
../accids.py -S${DBSERVER} -D${DBNAME} -U${DBUSER} -P${DBPASSWORDFILE} -O${MOUSEDATADIR} -T${MOUSEBUCKETZERO} >> ${LOG}

cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${MOUSEDATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >> ${LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${MOUSEDATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >> ${LOG}

date >> ${LOG}
echo "End: Mouse load" >> ${LOG}
