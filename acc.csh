#!/bin/csh -fx

#
# Creates and loads BCPs
#
# Usage:  acc.csh
#

cd `dirname $0` && source ./Configuration

setenv DATADIR $1
setenv TAXID $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

./accids.py
#cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${DATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}
#cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${DATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER}

date >> ${LOG}
