#!/bin/csh -fx

#
# Process all loads
#
# Usage:  loadAll.sh
#
# History
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

loadFiles.csh >> ${LOG}
mouse/load.csh >> ${LOG}
human/load.csh >> ${LOG}
rat/load.csh >> ${LOG}

date >> ${LOG}
