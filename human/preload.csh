#!/bin/csh -fx

#
# Pre-Load check for Human load
#
# Usage:  LLpreload.sh
#
# History
#
#	06/25/2002 lec
#	- TR 3827; copy reports to HUGO FTP directory
#
#	03/28/2001 lec
#	- TR 2665
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

setenv PRELOADDATE    `date '+%d-%m-%Y'`

# Run PreLoad QC Reports
# Save previous version/date tag each output file

foreach i (*.sql)
rm -rf ${HUMANDATADIR}/$i.rpt
echo ${HUMANARCHIVEDIR}
mv ${HUMANDATADIR}/$i.*.rpt ${HUMANARCHIVEDIR}
$i ${HUMANDATADIR}/$i.${PRELOADDATE}
ln -s ${HUMANDATADIR}/$i.${PRELOADDATE}.rpt ${HUMANDATADIR}/$i.rpt
end

foreach i (LL.preload1.sql.rpt LL.preload2.sql.rpt)
rcp ${HUMANDATADIR}/$i ${HUGOFTPDIR}
end

