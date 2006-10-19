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

cd `dirname $0` && source ../rat.config

${ENTREZGENELOAD}/archive.csh

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/deleteIDs.csh
${ENTREZGENELOAD}/createSets.csh
${ENTREZGENELOAD}/rat/createBuckets.csh
${ENTREZGENELOAD}/commonLoad-2.csh

date >> ${LOG}

