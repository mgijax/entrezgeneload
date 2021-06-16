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
# 06/14/2021    lec
#       - wts2-646/Switch load of Human gene to disease associations to use the Alliance file.
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

# _annottype_key = 1022
setenv ANNOTMODE                new
setenv ANNOTTYPENAME            "DO/Human Marker"
setenv ANNOTINPUTFILE           ${DATADIR}/annotations.hgnc
setenv ANNOTLOG                 ${ANNOTINPUTFILE}1.log
setenv ANNOTOBSOLETE            0
setenv DELETEREFERENCE          "J:306125"
setenv DELETEUSER               none

# Alliance human/mouse homology file for weekly/MGI_Cov_Human_Gene.py
setenv ALLIANCE_HUMAN_FILE     "/data/downloads/fms.alliancegenome.org/download/DISEASE-ALLIANCE_HUMAN.tsv"

${PYTHON} ${ENTREZGENELOAD}/human/annotations.py >>& ${LOG}
${PYTHON} ${ANNOTLOAD}/annotload.py >>& ${LOG}

date >> ${LOG}
