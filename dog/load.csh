#!/bin/csh -fx

#
# Process Dog Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ./Configuration

source ${ENTREZGENELOAD}/dog.config

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}
${ENTREZGENELOAD}/commonLoad-1.csh
date >> ${LOG}
