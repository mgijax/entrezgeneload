#!/bin/csh -fx

#
# Reports
#
# Usage:  runreports.csh
#
# History
#

source ../Configuration

setenv DATADIR	$1
setenv ARCHIVEDIR	$2

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
