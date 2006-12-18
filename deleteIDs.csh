#!/bin/csh -fx

#
# Program:
#	deleteIDs.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Delete Marker/ID associations for given Organism
#	Delete any obsolete Markers for given Organism
#
# Modification History:
#
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting Marker/ID associations..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh ${MGD_DBSERVER} ${MGD_DBNAME} $0 >>& ${LOG}
 
use ${MGD_DBNAME}
go

/* remove existing assocations by reference */

select a._Accession_key
into #todelete
from ACC_Accession a, ACC_AccessionReference r, MRK_Marker m 
where r._Refs_key = ${REFERENCEKEY}
and r._Accession_key = a._Accession_key 
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key in (${DELLOGICALDBBYREF})
and a._Object_key = m._Marker_key
and m._Organism_key = ${ORGANISM}
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

/* remove existing associations by logical DB only */
/* for example, RGD ids, RATMAP ids, etc. */

select a._Accession_key
into #todelete
from ACC_Accession a, MRK_Marker m 
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key in (${DELLOGICALDB})
and a._Object_key = m._Marker_key
and m._Organism_key = ${ORGANISM}
go

create index idx1 on #todelete(_Accession_key)
go

delete ACC_Accession
from #todelete d, ACC_Accession a
where d._Accession_key = a._Accession_key
go

drop table #todelete
go

/* remove synonyms by organism */

select s._Synonym_key
into #todelete
from MGI_Synonym s, MGI_SynonymType st
where s._SynonymType_key = st._SynonymType_key
and st._SynonymType_key = ${SYNTYPEKEY}
and st._Organism_key = ${ORGANISM}
go

create index idx1 on #todelete(_Synonym_key)
go

delete MGI_Synonym
from #todelete d, MGI_Synonym a
where d._Synonym_key = a._Synonym_key
go

drop table #todelete
go

/* remove obsolete markers by organism */

select obsoleteKey = a._Object_key, e.geneID, goodKey = x._Object_key
into #todelete
from ACC_Accession a, ${RADAR_DBNAME}..DP_EntrezGene_History e, ACC_Accession x
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID = ${ORGANISM}
and e.geneID != '-'
and e.geneID = x.accID
and x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
go

create index idx1 on #todelete(obsoleteKey)
create index idx2 on #todelete(goodKey)
go

/* if any of the "obsoleted" markers have orthology records, merge the orthology records */

declare merge_cursor cursor for
select d.obsoleteKey, d.goodKey
from #todelete d, HMD_Homology_Marker hm
where d.obsoleteOne = hm._Marker_key
for read only
go

declare @obsoleteKey integer
declare @goodKey integer

open merge_cursor
fetch merge_cursor into @obsoleteKey, @goodKey

while (@@sqlstatus = 0)
begin
	/* Merge Orthology records; this deletes obsolete marker */
	exec HMD_nomenUpdate @obsoleteKey, @goodKey
	fetch merge_cursor into @obsoleteKey, @goodKey
end

close merge_cursor
deallocate cursor merge_cursor
go

/* delete obsolete markers */

delete MRK_Marker
from #todelete d, MRK_Marker m
where d.obsoleteKey = m._Marker_key
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
 
echo "End: deleting Marker/ID associations." >> ${LOG}
