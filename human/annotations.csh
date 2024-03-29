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
# 	- TR12540/Disease Ontology (DO); annottype = 1022
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
setenv ANNOTOBSOLETE            0
setenv ANNOTINPUTFILE           ${DATADIR}/annotation.alliance
setenv ANNOTLOG                 ${ANNOTINPUTFILE}.log
setenv ALLIANCEINPUTFILE        ${DATADOWNLOADS}/fms.alliancegenome.org/download/DISEASE-ALLIANCE_HUMAN.tsv.gz
setenv DELETEREFERENCE          "J:98535"
setenv DELETEUSER               none

#
# copy file and gunzip
#
cp ${ALLIANCEINPUTFILE} ${DATADIR}
rm -rf DISEASE-ALLIANCE_HUMAN.tsv
gunzip DISEASE-ALLIANCE_HUMAN.tsv.gz 
grep "is_implicated_in" ${DATADIR}/DISEASE-ALLIANCE_HUMAN.tsv > ${DATADIR}/DISEASE-ALLIANCE_HUMAN.tsv.sorted
setenv ALLIANCEINPUTFILE           ${DATADIR}/DISEASE-ALLIANCE_HUMAN.tsv.sorted

# generate annotation file
${PYTHON} ${ENTREZGENELOAD}/human/annotations.py >>& ${LOG}

# process annotation file
${PYTHON} ${ANNOTLOAD}/annotload.py >>& ${LOG}

date >> ${LOG}
