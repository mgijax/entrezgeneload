#!/bin/csh -fx

#
# Process Rat Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteOrphans.csh ${RATDATADIR} ${RATSPECIESKEY}
../deleteRefSeqs.csh ${RATDATADIR} ${RATSPECIESKEY}
../convertToEG.csh ${RATDATADIR} ${RATSPECIESKEY}
./createSets.csh
./createBuckets.csh
../runreports.csh ${RATDATADIR} ${RATARCHIVEDIR}
../acc.csh ${RATDATADIR} ${RATTAXID}
../updateNomen.csh ${RATDATADIR} ${RATTAXID} ${RATSPECIESKEY}
../updateMapping.csh ${RATDATADIR} ${RATTAXID}

date >> ${LOG}
