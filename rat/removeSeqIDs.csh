#!/bin/csh -fx

#
# Remove Seq IDs loaded from RatMap that cannot be
# confirmed in LocusLink.
#
# Usage:  LLremoveSeqIDs.sh
#
# History
#
#	09/09/2003 lec
#	- TR 4342
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${RATDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}

use ${DBNAME}
go

select a._Accession_key, a.accID
into #ratseqIDs
from MRK_Marker m, ACC_Accession a, ACC_AccessionReference ar
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MGITYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
and a._Accession_key = ar._Accession_key
and ar._Refs_key = 68175
go

select a1._Accession_key
into #keepers
from #ratseqIDS r, ACC_Accession a1, ACC_Accession a2, ${RADARDB}..DP_LLAcc la, ${RADARDB}..DP_LL l
where r._Accession_key = a1._Accession_key
and a1._LogicalDB_key = ${LOGICALSEQKEY}
and a1.accID = la.genbankID
and a1._Object_key = a2._Object_key
and a2._MGIType_key = ${MGITYPEKEY}
and a2._LogicalDB_key = ${LOGICALRATMAPKEY}
and a2.accID = convert(varchar(30), l.mim)
and la.locusID = l.locusID
go

delete ACC_Accession
from #ratSeqIDs r, ACC_Accession a
where not exists (select 1 from #keepers k where r._Accession_key = k._Accession_key)
and r._Accession_key = a._Accession_key
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
