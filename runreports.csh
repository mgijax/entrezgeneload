#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	runreports.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Run reports in directory from which this program is callled
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

setenv DATADIR	$1
setenv ARCHIVEDIR $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Generating Reports..." >> $LOG
date >> $LOG

setenv LOADDATE    `date '+%d-%m-%Y'`

mkdir ${ARCHIVEDIR}/${LOADDATE}
mv ${DATADIR}/*.rpt ${ARCHIVEDIR}/${LOADDATE}

foreach i (preload*.sql)
$i ${DATADIR}/$i
end

foreach i (preload*.py)
$i
end

date >> $LOG
echo "Reports Generated." >>$LOG
