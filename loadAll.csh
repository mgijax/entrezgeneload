#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	loadAll.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to execute all EntrezGene loads (mouse, human, rat)
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
mouse/load.csh >> ${LOG}
human/load.csh >> ${LOG}
rat/load.csh >> ${LOG}

date >> ${LOG}
