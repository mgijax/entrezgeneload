#!/bin/csh -fx

#
# Create Work Tables for Processing Human data
#
# Usage:  createWorkFiles.sh
#
# History
#
#	10/16/2002 lec
#	- TR 4118; added LLHumanMappingUpdates
#
#	03/02/2001 lec
#	- TR 2265
#
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Creating Human Work Tables..." >> ${LOG}
date >> ${LOG}

# truncate tables
${RADARDBSCHEMADIR}/table/WRK_LL_Human_truncate.logical >> ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Human_drop.logical >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

/* delete orphans */

declare mrk_cursor cursor for
select _Marker_key
from MRK_Marker m
where m._Organism_key > 1
and not exists (select h.* from HMD_Homology_Marker h where m._Marker_key = h._Marker_key)
for read only
go

declare @markerKey integer

open mrk_cursor
fetch mrk_cursor into @markerKey

while (@@sqlstatus = 0)
begin
	delete MRK_Marker where _Marker_key = @markerKey
	fetch mrk_cursor into @markerKey
end

close mrk_cursor
deallocate cursor mrk_cursor
go

/* select duplicate EntrezGene records */

select l.geneID, l.symbol, d.dbXrefID
into #gdbIDs
from ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_EntrezGene_DBXRef d
where l.taxid = ${HUMANTAXID}
and l.geneID = d.geneID
and d.dbXrefID like 'GDB%'
go

/* duplicates by gdb id, locus ID or official symbol */

insert into ${RADARDB}..WRK_LLHumanDuplicates
select distinct geneID, dbXrefID, symbol
from #gdbIDs
where dbXrefID is not null
group by dbXrefID
having count(*) > 1
union
select distinct geneID, null, symbol
from ${RADARDB}..DP_EntrezGene_Info
where taxid = ${HUMANTAXID}
group by geneID
having count(*) > 1
union
select distinct geneID, null, symbol
from ${RADARDB}..DP_EntrezGene_Info
where taxid = ${HUMANTAXID}
group by symbol
having count(*) > 1
order by symbol
go

/* duplicate human symbols in MGD */

select _Marker_key, symbol
into #markers
from MRK_Marker
where _Organism_key = ${HUMANSPECIESKEY}
go

insert into ${RADARDB}..WRK_LLMGIHumanDuplicates
select *
from #markers
group by symbol having count(*) > 1
go

drop table #markers
go

/* add to LLHumanLLIDsToAdd all records w/ neither a EntrezGene ID nor a GDB ID and: */
/*	1. match to EntrezGene Official or Interim symbol */
/*	2. mRNA Seq ID in common between MGD and EntrezGene */

/* first, select all human markers w/ neither EntrezGene ID nor GDB ID */
select m._Marker_key, m.symbol
into #nonoset
from MRK_Marker m
where m._Organism_key = ${HUMANSPECIESKEY}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALGDBKEY})
go

delete #nonoset
from #nonoset m
where exists (select 1 from ${RADARDB}..WRK_LLHumanDuplicates d
where m.symbol = d.symbol)
or exists (select 1 from ${RADARDB}..WRK_LLMGIHumanDuplicates d
where m.symbol = d.symbol)
go

select m._Marker_key, l.geneID, l.symbol
into #markers
from #nonoset m, ${RADARDB}..DP_EntrezGene_Info l
where m.symbol = l.symbol
and l.taxID = ${HUMANTAXID}
go

/* add to LLHumanLLIDsToAdd all records w/ no EntrezGene ID but a GDB ID */

insert into ${RADARDB}..WRK_LLHumanLLIDsToAdd
select m._Marker_key, ${LOGICALLLKEY}, m.geneID, m.symbol, private = ${HUMANLLPRIVATE}
from #markers m, ${RADARDB}..DP_LLAcc a, ACC_Accession ma
where m.geneID = a.geneID
and a.genbankID not like "NM%"
and a.seqType = "m"
and a.genbankID = ma.accID
and ma._Object_key = m._Marker_key
and ma._MGIType_key = ${MARKERTYPEKEY}
union
select m._Marker_key, ${LOGICALLLKEY}, l.geneID, l.symbol, private = ${HUMANLLPRIVATE}
from MRK_Marker m, ACC_Accession a, ${RADARDB}..DP_EntrezGene_Info l, #gdbIDs g
where m._Organism_key = ${HUMANSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALGDBKEY}
and a.accID = g.dbXrefID
and g.geneID = l.geneID
and l.taxID = ${HUMANTAXID}
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLHumanDuplicates d
where m.symbol = d.symbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIHumanDuplicates d
where m.symbol = d.symbol)
go

/* add to LLHumanGDBIDsToAdd all records from LLHUmanLLIDsToAdd which have GDB IDs */
/* add to LLHumanGDBIDsToAdd all records w/ EntrezGene ID and no GDB ID */

insert into ${RADARDB}..WRK_LLHumanGDBIDsToAdd
select m._Marker_key, ${LOGICALGDBKEY}, g.dbXrefID, private = ${HUMANGDBPRIVATE}
from ${RADARDB}..WRK_LLHumanLLIDsToAdd m, #gdbIDs g
where m.geneID = g.geneID
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALGDBKEY})
union
select m._Marker_key, ${LOGICALGDBKEY}, g.dbXrefID, private = ${HUMANGDBPRIVATE}
from MRK_Marker m, ACC_Accession a, ${RADARDB}..DP_EntrezGene_Info l, #gdbIDs g
where m._Organism_key = ${HUMANSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.geneID
and l.taxID = ${HUMANTAXID}
and l.geneID = g.geneID
and not exists (select 1 from ACC_Accession ma
where m._Marker_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALGDBKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLHumanDuplicates d
where m.symbol = d.symbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIHumanDuplicates d
where m.symbol = d.symbol)
go

/* add to LLHumanRefSeqIDsToAdd all records w/ EntrezGene ID */
insert into ${RADARDB}..WRK_LLHumanRefSeqIDsToAdd
select m._Object_key, ${LOGICALREFSEQKEY}, lr.rna, private = ${HUMANREFSEQPRIVATE}
from ACC_Accession m, ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_EntrezGene_RefSeq lr
where m._LogicalDB_key = ${LOGICALLLKEY}
and m._MGIType_key = ${MARKERTYPEKEY}
and m.accID = l.geneID
and l.taxID = ${HUMANTAXID}
and l.geneID = lr.geneID
and lr.rna like 'NM%'
go

/* add to LLHumanNomenUpdates all records w/ EntrezGene and Nomenclature Updates */

insert into ${RADARDB}..WRK_LLHumanNomenUpdates
select m._Marker_key, m.symbol, m.name, l.symbol, lname = l.name
from ${RADARDB}..WRK_LLHumanLLIDsToAdd ml, MRK_Marker m, ${RADARDB}..DP_EntrezGene_Info l
where ml._Marker_key = m._Marker_key
and ml.geneID = l.geneID
and (m.symbol != l.symbol or m.name != l.name)
union
select m._Marker_key, m.symbol, m.name, l.symbol, lname = l.name
from MRK_Marker m, ACC_Accession a, ${RADARDB}..DP_EntrezGene_Info l
where m._Organism_key = ${HUMANSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.geneID
and (m.symbol != l.symbol or m.name != l.name)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIHumanDuplicates d
where m.symbol = d.symbol)
order by symbol
go

insert into ${RADARDB}..WRK_LLHumanMappingUpdates
select m._Marker_key, m.symbol, m.chromosome, m.cytogeneticOffset, l.chromosome, l.mapPosition, l.geneID
from ${RADARDB}..WRK_LLHumanLLIDsToAdd ml, MRK_Marker m, ${RADARDB}..DP_EntrezGene_Info l
where ml._Marker_key = m._Marker_key
and m._Organism_key = ${HUMANSPECIESKEY}
and ml.geneID = l.geneID
union
select m._Marker_key, m.symbol, m.chromosome, m.cytogeneticOffset, l.chromosome, l.mapPosition, l.geneID
from MRK_Marker m, ACC_Accession a, ${RADARDB}..DP_EntrezGene_Info l
where m._Organism_key = ${HUMANSPECIESKEY}
and m._Marker_key = a._Object_key
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.geneID
go

/* convert the EntrezGene mapPosition values to MGI format (remove the leading chromosome value) */

update ${RADARDB}..WRK_LLHumanMappingUpdates
set llMap = substring(llMap, 3, 100)
where llMap like '[12][0-9]%'
go

update ${RADARDB}..WRK_LLHumanMappingUpdates
set llMap = substring(llMap, 2, 100)
where llMap like '[1-9]%'
or llMap like '[xy]%'
go

update ${RADARDB}..WRK_LLHumanMappingUpdates
set llMap = NULL
where llMap like '[1-9]'
go

update ${RADARDB}..WRK_LLHumanMappingUpdates
set llChr = "MT", llMap = NULL
where llChr = "mitochon"
go

delete from ${RADARDB}..WRK_LLHumanMappingUpdates
where llChr = "MT" or 
llChr = null or 
(mgiChr = llChr and mgiOff = llMap)
or
(mgiChr = llChr and llMap = null)
go

quit
 
EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Human_create.logical >> ${LOG}

# permissions
${RADARDBPERMSDIR}/public/table/WRK_LL_Human_grant.logical >>& ${LOG}

date >> ${LOG}
echo "Finished creating Human Work Tables." >> ${LOG}
