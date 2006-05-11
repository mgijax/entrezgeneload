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
../createSets.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
./createBuckets.csh
../acc.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../syns.csh ${RATDATADIR} ${RATTAXID} ${RATSYNTYPEKEY}
../updateNomen.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../updateMapping.csh ${RATDATADIR} ${RATTAXID}
../deleteObsolete.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../runreports.csh ${RATDATADIR}

date >> ${LOG}

