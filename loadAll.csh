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

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

loadFiles.sh >> ${LOG}
mouse/load.sh >> ${LOG}
human/load.sh >> ${LOG}
rat/load.sh >> ${LOG}

date >> ${LOG}
