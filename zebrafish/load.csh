#!/bin/csh -f

#
# Process Zebrafish Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../zebrafish.config

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}
${ENTREZGENELOAD}/deleteIDs.csh
${ENTREZGENELOAD}/createSets.csh
${ENTREZGENELOAD}/zebrafish/createBuckets.csh
${ENTREZGENELOAD}/commonLoad-2.csh
date >> ${LOG}
