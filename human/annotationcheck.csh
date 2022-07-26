#!/bin/csh -f

#
# Template
#


if ( ${?MGICONFIG} == 0 ) then
        setenv MGICONFIG /usr/local/mgi/live/mgiconfig
endif

source ${MGICONFIG}/master.config.csh

cd `dirname $0`

setenv LOG $0.log
rm -rf $LOG
touch $LOG
 
date | tee -a $LOG
 
cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 | tee -a $LOG

select m.symbol, t.term, a.accid
from voc_annot v, mrk_marker m, voc_term t, acc_accession a
where v._annottype_key = 1022
and v._object_key = m._marker_key
and v._term_key = t._term_key
and v._term_key = a._object_key
and a._mgitype_key = 13
and a._logicaldb_key = 191
and a.prefixpart = 'DOID:'
order by m.symbol, t.term
;

EOSQL

date |tee -a $LOG

