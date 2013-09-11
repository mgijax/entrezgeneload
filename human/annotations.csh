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

setenv ANNOTTYPENAME1           "OMIM/Human Marker"
setenv ANNOTTYPENAME2           "OMIM/Human Marker/Phenotype"
setenv ANNOTINPUTFILE1          ${DATADIR}/annotations.omim1
setenv ANNOTINPUTFILE2          ${DATADIR}/annotations.omim2
setenv ANNOTLOG1                ${ANNOTINPUTFILE}1.log
setenv ANNOTLOG2                ${ANNOTINPUTFILE}2.log

${ENTREZGENELOAD}/human/annotations.py >>& ${LOG}

setenv ANNOTMODE                new
setenv ANNOTTYPENAME            ${ANNOTTYPENAME1}
setenv ANNOTINPUTFILE           ${ANNOTINPUTFILE1}
setenv ANNOTLOG                 ${ANNOTLOG1}
setenv ANNOTOBSOLETE            0

${ANNOTLOAD}/annotload.py >>& ${LOG}

setenv ANNOTMODE                new
setenv ANNOTTYPENAME            ${ANNOTTYPENAME2}
setenv ANNOTINPUTFILE           ${ANNOTINPUTFILE2}
setenv ANNOTLOG                 ${ANNOTLOG2}
setenv ANNOTOBSOLETE            0

${ANNOTLOAD}/annotload.py >>& ${LOG}

date >> ${LOG}
