#!/bin/csh -fx

#
# Post-Load check for Rat load
#
# Usage:  LLpostload.sh
#
# History
#
#	09/11/2003	lec
#	- TR 4342
#

cd `dirname $0` && source ../Configuration

setenv POSTLOADDATE    `date '+%d-%m-%Y'`

# Run PostLoad QC Reports
# Save previous version/date tag each output file

foreach i (*postload*.sql)
rm -rf ${RATDATADIR}/${i}.rpt
mv ${RATDATADIR}/${i}.*.rpt ${RATARCHIVEDIR}
${i} ${RATDATADIR}/${i}.${POSTLOADDATE}
ln -s ${RATDATADIR}/${i}.${POSTLOADDATE}.rpt ${RATDATADIR}/${i}.rpt
end

