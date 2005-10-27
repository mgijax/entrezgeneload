#!/bin/csh -fx

#
# Process Rat Updates
#
# Usage:  load.csh
#
# History
#
#	09/15/2005 lec
#	- TR 5972 - add load of SwissProt, NP, XP
#
#

cd `dirname $0` && source ../Configuration

../archive.csh ${RATDATADIR} ${RATARCHIVEDIR}

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteIDs.csh ${RATDATADIR} ${RATSPECIESKEY} "${LOGICALREFSEQKEY}" "${LOGICALRGDKEY},${LOGICALRATMAPKEY}" ${RATSYNTYPEKEY}

#
# for PIRSF implementation only...this really only has to be run once
#
../deleteIDs.csh ${RATDATADIR} ${RATSPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "${LOGICALREFSEQKEY},${LOGICALSPKEY}" ${RATSYNTYPEKEY}
#
#
#

../createSets.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
./createBuckets.csh
../runreports.csh ${RATDATADIR}
../acc.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../syns.csh ${RATDATADIR} ${RATTAXID} ${RATSYNTYPEKEY}
../updateNomen.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../updateMapping.csh ${RATDATADIR} ${RATTAXID}
../deleteObsolete.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
${DBUTILSBINDIR}/runDeleteObsoleteDummy.csh ${DBSERVER} ${DBNAME}
${SEQCACHELOAD}/seqdummy.csh

date >> ${LOG}

