#!/bin/csh -fx

#
# Pre-Load check for Mouse load
#
# Usage:  LLpreload.sh
#
# History
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Generating Preload Reports..." >> $LOG
date >> $LOG

setenv LOADDATE    `date '+%d-%m-%Y'`

# Run PreLoad QC Reports
# Save previous version/date tag each output file

mkdir ${MOUSEARCHIVEDIR}/${LOADDATE}
mv ${MOUSEDATADIR}/*.rpt ${MOUSEARCHIVEDIR}/${LOADDATE}

foreach i (preload*.sql)
$i ${MOUSEDATADIR}/$i
end

foreach i (preload*.py)
$i
end

date >> $LOG
echo "Preload Reports Generated." >>$LOG
