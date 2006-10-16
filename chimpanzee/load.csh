#!/bin/csh -fx

#
# Process Chimpanzee Updates
#
# Usage:  load.csh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${CHIMPDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}
../commonLoad.csh ${CHIMPDATADIR} ${CHIMPARCHIVEDIR} ${CHIMPTAXID} ${CHIMPSPECIESKEY} ${CHIMPSYNTYPEKEY} | tee -a ${LOG}
date >> ${LOG}

