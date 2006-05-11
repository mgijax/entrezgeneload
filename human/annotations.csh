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

cd `dirname $0` && source ../Configuration

setenv DATADIR $1

setenv ANNOTATIONTYPENAME       "OMIM/Human Marker"
setenv ANNOTATIONFILE		${DATADIR}/annotations.omim

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

./annotations.py >>& ${LOG}
cd ${DATADIR}
${ANNOTLOAD}/annotload.py -S${MGD_DBSERVER} -D${MGD_DBNAME} -U${MGD_DBUSER} -P${MGD_DBPASSWORDFILE} -M${ANNOTMODE} -I${ANNOTATIONFILE} -A"${ANNOTATIONTYPENAME}" -R${ANNOTREFERENCE}

date >> ${LOG}
