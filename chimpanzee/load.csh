#!/bin/csh -fx

#
# Process Chimpanzee Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ./Configuration

source ${ENTREZGENELOAD}/chimpanzee.config

setenv LOG      ${CHIMPDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}
${ENTREZGENELOAD}/commonLoad-1.csh
date >> ${LOG}
