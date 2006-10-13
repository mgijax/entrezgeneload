#!/bin/csh -fx

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
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

source ../Configuration

setenv DATADIR	$1

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Generating Reports..." >> $LOG
date >> $LOG

foreach i (preload*.sql)
${REPORTHEADER} ${DATADIR}/$i.rpt
$i ${DATADIR}/$i.rpt
end

foreach i (preload*.py)
$i
end

date >> $LOG
echo "Reports Generated." >>$LOG
