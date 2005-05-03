#!/bin/csh -fx

#
# Delete existing EntrezGene associations
#
# Usage:  deleteExistingEntries.csh
#
# History
#	

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting existing EntrezGene associations..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

select m._Marker_key
into #markers
from MRK_Marker m
where m._Organism_key = ${MOUSESPECIESKEY}
go

create index idx1 on #markers(_Marker_key)
go

/* remove existing EntrezGene assocations */

select a._Accession_key
into #todelete
from #markers m, ACC_Accession a, ACC_AccessionReference r
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Accession_key = r._Accession_key 
and r._Refs_key = ${REFERENCEKEY}
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

drop table #todelete
go

/* remove existing GenBank associations made via the SwissProt load */

select a._Accession_key
into #todelete
from #markers m, ACC_Accession a, ACC_AccessionReference r
where m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
and a._Accession_key = r._Accession_key 
and r._Refs_key = ${SPREFERENCEKEY}
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
echo "End: deleting existing EntrezGene associations." >> ${LOG}
