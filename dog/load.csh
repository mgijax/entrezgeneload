#!/bin/csh -fx

#
# Process Dog Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${DOGDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../commonLoad.csh ${DOGDATADIR} ${DOGARCHIVEDIR} ${DOGTAXID} ${DOGSPECIESKEY} ${DOGSYNTYPEKEY}

date >> ${LOG}
