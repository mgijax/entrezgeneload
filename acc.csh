#!/bin/csh -fx

# $Header$
# $Name$

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
# 01/03/2004 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#


setenv DATADIR $1
setenv TAXID $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

./accids.py
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_Accession in ${DATADIR}/ACC_Accession.bcp -c -t\| -S${DBSERVER} -U${DBUSER} >>& $LOG}
cat ${DBPASSWORDFILE} | bcp ${DBNAME}..ACC_AccessionReference in ${DATADIR}/ACC_AccessionReference.bcp -c -t\| -S${DBSERVER} -U${DBUSER}

date >> ${LOG}
