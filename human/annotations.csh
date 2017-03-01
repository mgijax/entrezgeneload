#!/bin/csh -f

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
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 03/01/2017	lec
# 	- TR12540/Disease Ontology (DO)
#
# 09/22/2016    lec
#	"OMIM/Human Marker/Pheno" is obsolete/removed
#
# 09/12/2013	lec
#	- TR11423/add new annotation type
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

setenv ANNOTMODE                new
setenv ANNOTTYPENAME            "DO/Human Marker"
setenv ANNOTINPUTFILE           ${DATADIR}/annotations.omim1
setenv ANNOTLOG                 ${ANNOTINPUTFILE}1.log
setenv ANNOTOBSOLETE            0

${ENTREZGENELOAD}/human/annotations.py >>& ${LOG}

${ANNOTLOAD}/annotload.py >>& ${LOG}

date >> ${LOG}
