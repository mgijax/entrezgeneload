#!/bin/csh -fx

#
# Program:
#	loadAll.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to execute all EntrezGene loads (human, rat)
#
# Requirements Satisfied by This Program:
#
# Usage:
#
# Envvars:
#
# Inputs:
#
# Outputs:
#
# Exit Codes:
#
# Assumes:
#
# Bugs:
#
# Implementation:
#
#    Modules:
#
# Modification History:
#
#
# 05/24/2005 - lec
#	- TR 6046; removing mouse....mouse load is now done by the "egload" product
#
# 01/03/2004 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

loadFiles.csh >> ${LOG}
updateIDs.csh >> ${LOG}
human/load.csh >> ${LOG}
rat/load.csh >> ${LOG}
dog/load.csh >> ${LOG}
chimp/load.csh >> ${LOG}

date >> ${LOG}
