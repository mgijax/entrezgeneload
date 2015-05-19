#!/bin/csh -f

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
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/accids.py >>& ${LOG}

${PG_DBUTILS}/bin/bcpin.csh ${PG_DBSERVER} ${PG_DBNAME} MRK_Marker ${DATADIR} MRK_Marker.bcp "\t" "\n" radar

${PG_DBUTILS}/bin/bcpin.csh ${PG_DBSERVER} ${PG_DBNAME} ACC_Accession ${DATADIR} ACC_Accession.bcp "\t" "\n" radar

${PG_DBUTILS}/bin/bcpin.csh ${PG_DBSERVER} ${PG_DBNAME} ACC_AccessionReference ${DATADIR} ACC_AccessionReference.bcp "\t" "\n" radar

date >> ${LOG}
