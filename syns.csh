#!/bin/csh -fx

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


setenv DATADIR $1
setenv TAXID $2
setenv SYNTYPEKEY $3

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../syns.py >>& ${LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..MGI_Synonym in ${DATADIR}/MGI_Synonym.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& ${LOG}

date >> ${LOG}
