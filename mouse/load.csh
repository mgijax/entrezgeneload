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
../acc.csh ${MOUSEDATADIR} ${MOUSETAXID}

date >> ${LOG}
