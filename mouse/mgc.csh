#!/bin/csh -fx

#
# Process Mouse LocusLink Load Bucket 10 for loading into Nomen
#
# Usage:  LLmgc.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      $MOUSEDATADIR/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Processing MGC from Bucket 10..." >> $LOG
date >> $LOG

LLmgc.py -S$DBSERVER -D$DBNAME -U$DBUSER -P$DBPASSWORDFILE -O$MGCFILE >>& $LOG
cd $MOUSEDATADIR
$NOMENLOAD -S$DBSERVER -D$DBNAME -U$DBUSER -P$DBPASSWORDFILE -I$MGCFILE -Mload >>& $LOG

date >> $LOG
echo "Finished Processing MGC." >> $LOG
