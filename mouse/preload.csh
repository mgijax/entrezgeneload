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

setenv LOG      $MOUSEDATADIR/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Generating Preload Reports..." >> $LOG
date >> $LOG

setenv PRELOADDATE    `date '+%d-%m-%Y'`

# Run PreLoad QC Reports
# Save previous version/date tag each output file

foreach i (LL.preload*.sql)
rm -rf $MOUSEDATADIR/$i.rpt
mv $MOUSEDATADIR/$i.*.rpt $MOUSEARCHIVEDIR
$i $MOUSEDATADIR/$i.$PRELOADDATE
ln -s $MOUSEDATADIR/$i.$PRELOADDATE.rpt $MOUSEDATADIR/$i.rpt
end

foreach i (LL.preload*.py)
set r=`basename $i .py`
rm -rf $MOUSEDATADIR/$r.rpt
mv $MOUSEDATADIR/$r.*.rpt $MOUSEARCHIVEDIR
$i
mv $MOUSEDATADIR/$r.rpt $MOUSEDATADIR/$r.$PRELOADDATE.rpt
ln -s $MOUSEDATADIR/$r.$PRELOADDATE.rpt $MOUSEDATADIR/$r.rpt
end

date >> $LOG
echo "Preload Reports Generated." >>$LOG
