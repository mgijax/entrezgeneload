#!/bin/csh -fx

#
# Process Human Updates
#
# Usage:  load.csh
#
# History
#
#	12/15/2003 lec
#	- TR 5382; human refseqs
#
#	03/02/2001 lec
#	- TR 2265
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

deleteOrphans.csh
deleteRefSeqs.csh
createSets.csh
createBuckets.csh

# run reports
preload.csh >>& ${LOG}

# process accession ids
../accids.py -S${DBSERVER} -D${DBNAME} -U${DBUSER} -P${DBPASSWORDFILE} -O${HUMANDATADIR} -T${HUMANBUCKETZERO} >> $LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${HUMANDATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >> $LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${HUMANDATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >> $LOG}

# update nomenclature
update.csh >>& ${LOG}

date >> ${LOG}
