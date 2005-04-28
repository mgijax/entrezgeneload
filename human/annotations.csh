#!/bin/csh -fx

# $Header$

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


setenv DATADIR $1

setenv ANNOTATIONTYPENAME       "OMIM/Human Marker"
setenv ANNOTATIONFILE		${DATADIR}/annotations.omim

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

./annotations.py >>& ${LOG}
${ANNOTLOAD}/annotload.py -S${DBSERVER} -D${DBNAME} -U${DBUSER} -P${DBPASSWORDFILE} -M${ANNOTMODE} -I${ANNOTATIONFILE} -A"${ANNOTATIONTYPENAME}" -R${ANNOTREFERENCE}

date >> ${LOG}
