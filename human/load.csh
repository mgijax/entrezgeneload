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

./deleteOrphans.csh
./deleteRefSeqs.csh
./convertToEG.csh
./createSets.csh
./createBuckets.csh
../runreports.csh ${HUMANDATADIR} ${HUMANARCHIVEDIR}
../accids.py -O${HUMANDATADIR} -T${HUMANTAXID}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${HUMANDATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${HUMANDATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}
../updateNomen.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
../updateMapping.csh ${HUMANDATADIR} ${HUMANTAXID}

date >> ${LOG}
