#!/bin/csh -fx

#
# Program:
#	archive.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Archive previous load files
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
# 01/05/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv DATADIR	$1
setenv ARCHIVEDIR $2
setenv LOADDATE    `date '+%d-%m-%Y'`

mkdir ${ARCHIVEDIR}/${LOADDATE}
mv ${DATADIR}/* ${ARCHIVEDIR}/${LOADDATE}

