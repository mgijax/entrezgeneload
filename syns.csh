#!/bin/csh -f

#
# Program:
#	syns.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to generate Synonym BCP file and bcp them into MGI
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
#	- TR 5626
#


setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/syns.py >>& ${LOG}

date >> ${LOG}
