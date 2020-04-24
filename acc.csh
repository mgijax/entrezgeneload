#!/bin/csh -f

#
# Program:
#	acc.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to generate ACC BCP files and bcp them into MGI
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
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${PYTHON} ${ENTREZGENELOAD}/accids.py >>& ${LOG}

date >> ${LOG}
