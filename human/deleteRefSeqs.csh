#!/bin/csh -fx

#
# Delete RefSeq/Human Marker associations
#
# Usage:  deleteRefSeqs.csh
#
# History
#	

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting RefSeq/Human markers associations..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go


/* remove existing LL assocations */

select a._Accession_key
into #todelete
from ACC_Accession a, ACC_AccessionReference r, MRK_Marker m 
where r._Refs_key = ${REFERENCEKEY}
and r._Accession_key = a._Accession_key 
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALREFSEQKEY}
and a._Object_key = m._Marker_key
and m._Organism_key = ${HUMANSPECIESKEY}
go

create index idx1 on #todelete(_Accession_key)
go

delete ACC_AccessionReference
from #todelete d, ACC_AccessionReference a
where d._Accession_key = a._Accession_key
go

delete ACC_Accession
from #todelete d, ACC_Accession a
where d._Accession_key = a._Accession_key
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: deleting RefSeq/Human markers associations." >> ${LOG}
