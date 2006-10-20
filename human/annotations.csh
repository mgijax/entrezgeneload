#!/bin/csh -fx

#
# Program:
#	annotations.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to generate input file for Annotation loader and to call Annotation loader
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
# 04/28/2005
#	- TR 3853, OMIM
#

cd `dirname $0` && source ../human.config

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cd ${DATADIR}
${ENTREZGENELOAD}/human/annotations.py >>& ${LOG}
${ANNOTLOAD}/annotload.py >>& ${LOG}

date >> ${LOG}
