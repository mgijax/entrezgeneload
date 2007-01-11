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
#	Delete duplicate Markers for given Organism
#	Delete obsolete Markers for given Organism
#
# Modification History:
#
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting Marker/ID associations, duplicate and obsolete Markers..." >> ${LOG}
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

/* remove duplicate markers by tax id */

select duplicateKey = a._Object_key, e.geneID, goodKey = x._Object_key
into #todelete
from ACC_Accession a, ${RADAR_DBNAME}..DP_EntrezGene_History e, ACC_Accession x
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID = ${TAXID}
and e.geneID != '-'
and e.geneID = x.accID
and x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
go

create index idx1 on #todelete(duplicateKey)
create index idx2 on #todelete(goodKey)
go

/* delete duplicate markers for those that don't have orthology records */
/* those that *do* have orthology records will be listed in a qc report */

delete MRK_Marker
from #todelete d, MRK_Marker m
where d.duplicateKey = m._Marker_key
and not exists (select 1 from HMD_Homology_Marker h where d.duplicateKey = h._Marker_key)
go

select * from #todelete order by geneID
go

drop table #todelete
go

/* delete any obsolete markers */
/* those that don't have an orthology record and their gene id does not exist in EntrezGene */

select m._Marker_key, m.symbol
into #todelete
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select h.* from HMD_Homology_Marker h where m._Marker_key = h._Marker_key)
and not exists (select e.* from ${RADAR_DBNAME}..DP_EntrezGene_Info e, ACC_Accession a
	where e.taxID = ${TAXID}
	and m._Marker_key = a._Object_key
	and a._MGIType_key = ${MARKERTYPEKEY}
	and a._LogicalDB_key = ${LOGICALEGKEY}
	and a.accID = e.geneID)
go

create index idx1 on #todelete(_Marker_key)
go

delete MRK_Marker
from #todelete d, MRK_Marker m
where d._Marker_key = m._Marker_key
go

select * from #todelete order by symbol
go

drop table #todelete
go

/* delete any obsolete markers */
/* those that don't have an orthology record and their gene id does not exist in MGI */

select m._Marker_key, m.symbol
into #todelete
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select h.* from HMD_Homology_Marker h where m._Marker_key = h._Marker_key)
and not exists (select a.* from ACC_Accession a
	where m._Marker_key = a._Object_key
	and a._MGIType_key = ${MARKERTYPEKEY}
	and a._LogicalDB_key = ${LOGICALEGKEY})
go

create index idx1 on #todelete(_Marker_key)
go

delete MRK_Marker
from #todelete d, MRK_Marker m
where d._Marker_key = m._Marker_key
go

select * from #todelete order by symbol
go

checkpoint
go

quit
 
EOSQL
 
date >> ${LOG}
 
echo "End: deleting Marker/ID associations, duplicate and obsolete Markers." >> ${LOG}
