#!/bin/csh -fx

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
cat ${MGD_DBPASSWORDFILE} | bcp ${MGD_DBNAME}..MRK_Marker in ${DATADIR}/MRK_Marker.bcp -c -t\\t -S${MGD_DBSERVER} -U${MGD_DBUSER} >>& ${LOG}
cat ${MGD_DBPASSWORDFILE} | bcp ${MGD_DBNAME}..ACC_Accession in ${DATADIR}/ACC_Accession.bcp -c -t\\t -S${MGD_DBSERVER} -U${MGD_DBUSER} >>& ${LOG}
cat ${MGD_DBPASSWORDFILE} | bcp ${MGD_DBNAME}..ACC_AccessionReference in ${DATADIR}/ACC_AccessionReference.bcp -c -t\\t -S${MGD_DBSERVER} -U${MGD_DBUSER} >>& ${LOG}

date >> ${LOG}
