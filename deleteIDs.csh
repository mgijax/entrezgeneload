#!/bin/csh -f

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

#cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0

/* remove existing assocations by reference */

CREATE TEMP TABLE toDelete
as select a._Accession_key
from ACC_Accession a, ACC_AccessionReference r, MRK_Marker m 
where r._Refs_key = ${REFERENCEKEY}
and r._Accession_key = a._Accession_key 
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key in (${DELLOGICALDBBYREF})
and a._Object_key = m._Marker_key
and m._Organism_key = ${ORGANISM}
;

create index idx1 on toDelete(_Accession_key)
;

delete from ACC_AccessionReference
using toDelete d
where d._Accession_key = ACC_AccessionReference._Accession_key
;

delete from ACC_Accession
using toDelete d
where d._Accession_key = ACC_Accession._Accession_key
;

drop table toDelete
;

/* remove existing associations by logical DB only */
/* for example, RGD ids, RATMAP ids, etc. */

CREATE TEMP TABLE toDelete
as select a._Accession_key
from ACC_Accession a, MRK_Marker m 
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key in (${DELLOGICALDB})
and a._Object_key = m._Marker_key
and m._Organism_key = ${ORGANISM}
;

create index idx1 on toDelete(_Accession_key)
;

delete from ACC_Accession
using toDelete d
where d._Accession_key = ACC_Accession._Accession_key
;

drop table toDelete
;

/* remove synonyms by organism */

CREATE TEMP TABLE toDelete
as select s._Synonym_key
from MGI_Synonym s, MGI_SynonymType st
where s._SynonymType_key = st._SynonymType_key
and st._SynonymType_key = ${SYNTYPEKEY}
and st._Organism_key = ${ORGANISM}
;

create index idx1 on toDelete(_Synonym_key)
;

delete from MGI_Synonym
using toDelete d
where d._Synonym_key = MGI_Synonym._Synonym_key
;

drop table toDelete
;

/* remove duplicate markers by tax id */

CREATE TEMP TABLE toDelete
as select a._Object_key as duplicateKey, e.geneID, x._Object_key as goodKey
from ACC_Accession a, DP_EntrezGene_History e, ACC_Accession x
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALEGKEY}
and a.accID = e.oldgeneID
and e.taxID = ${TAXID}
and e.geneID != '-'
and e.geneID = x.accID
and x._MGIType_key = ${MARKERTYPEKEY}
and x._LogicalDB_key = ${LOGICALEGKEY}
and not exists (select 1 from MRK_ClusterMember cm where a._Object_key = cm._Marker_key)
;

create index idx1 on toDelete(duplicateKey)
;
create index idx2 on toDelete(goodKey)
;

/* delete duplicate markers for those that don't have orthology records */
/* those that *do* have orthology records will be listed in a qc report */

delete from MRK_Marker
using toDelete d
where d.duplicateKey = MRK_Marker._Marker_key
;

select * from toDelete order by geneID
;

drop table toDelete
;

/* delete any obsolete markers */
/* those that don't have an orthology record and their gene id does not exist in EntrezGene */

CREATE TEMP TABLE toDelete
as select m._Marker_key, m.symbol
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (SELECT 1 from MRK_ClusterMember cm where m._Marker_key = cm._Marker_key)
and not exists (SELECT 1 from DP_EntrezGene_Info e, ACC_Accession a
	where e.taxID = ${TAXID}
	and m._Marker_key = a._Object_key
	and a._MGIType_key = ${MARKERTYPEKEY}
	and a._LogicalDB_key = ${LOGICALEGKEY}
	and a.accID = e.geneID)
;

create index idx1 on toDelete(_Marker_key)
;

delete from MRK_Marker
using toDelete d
where d._Marker_key = MRK_Marker._Marker_key
;

select * from toDelete order by symbol
;

drop table toDelete
;

/* delete any obsolete markers */
/* those that don't have an orthology record and their gene id does not exist in MGI */

CREATE TEMP TABLE toDelete
as select m._Marker_key, m.symbol
from MRK_Marker m
where m._Organism_key = ${ORGANISM}
and not exists (select 1 from MRK_ClusterMember cm where m._Marker_key = cm._Marker_key)
and not exists (select 1 from ACC_Accession a
	where m._Marker_key = a._Object_key
	and a._MGIType_key = ${MARKERTYPEKEY}
	and a._LogicalDB_key = ${LOGICALEGKEY})
;

create index idx1 on toDelete(_Marker_key)
;

delete from MRK_Marker
using toDelete d
where d._Marker_key = MRK_Marker._Marker_key
;

select * from toDelete order by symbol
;

EOSQL
 
date >> ${LOG}
 
echo "End: deleting Marker/ID associations, duplicate and obsolete Markers." >> ${LOG}
