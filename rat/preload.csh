#!/bin/csh -fx

#
# Pre-Load check for Rat load
#
# Usage:  LLpreload.sh
#
# History
#
#	09/11/2003	lec
#	- TR 4342
#

cd `dirname $0` && source ../Configuration

setenv PRELOADDATE    `date '+%d-%m-%Y'`

# Run PreLoad QC Reports
# Save previous version/date tag each output file

foreach i (*preload*.sql)
rm -rf ${RATDATADIR}/${i}.rpt
mv ${RATDATADIR}/${i}.*.rpt ${RATARCHIVEDIR}
${i} ${RATDATADIR}/${i}.${PRELOADDATE}
ln -s ${RATDATADIR}/${i}.${PRELOADDATE}.rpt ${RATDATADIR}/${i}.rpt
end

