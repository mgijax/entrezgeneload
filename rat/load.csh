#!/bin/csh -fx

#
# Process Rat Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../Configuration

../archive.csh ${RATDATADIR} ${RATARCHIVEDIR}

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteOrphans.csh ${RATDATADIR} ${RATSPECIESKEY}
../deleteIDs.csh ${RATDATADIR} ${RATSPECIESKEY} "${LOGICALREFSEQKEY}" "${LOGICALRGDKEY},${LOGICALRATMAPKEY}"
../createSets.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
./createBuckets.csh
../acc.csh ${RATDATADIR} ${RATTAXID}
../updateNomen.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../updateMapping.csh ${RATDATADIR} ${RATTAXID}
../runreports.csh ${RATDATADIR}

date >> ${LOG}
