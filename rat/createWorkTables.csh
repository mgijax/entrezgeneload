#!/bin/csh -fx

#
# Creato Temp Tables for Processing Rat data
#
# Usage:  createTempFiles.sh
#
o History
#
#	08/26/2003	lec
#	- TR 4342
#
#

cd `dirname $0` && source ../Configuration

setenv LOG      $RATDATADIR/`basename $0`.log
rm -rf $LOG
touch $LOG

echo "Creating Rat Temp Tables..." >> $LOG
date >> $LOG

# truncate tables
${RADARDBSCHEMADIR}/table/WRK_LL_Rat_truncate.logical >>& ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Rat_drop.logical >>& ${LOG}

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

/* select duplicate LL records */

select locusID, gsdbID, osymbol, ratmapID = convert(varchar(30), mim)
into #llsymbols
from ${RADARDB}..DP_LL
where taxid = ${RATTAXID}
and osymbol is not null
union
select locusID, gsdbID, isymbol, ratmapID = convert(varchar(30), mim)
from ${RADARDB}..DP_LL
where taxid = ${RATTAXID}
and isymbol is not null
go

/* duplicates by rgd id, locus ID, ratmap ID or official symbol */

insert into ${RADARDB}..WRK_LLRatDuplicates
select distinct locusID, gsdbID, osymbol, ratmapID
from #llsymbols
where gsdbID is not null
group by gsdbID
having count(*) > 1
union
select distinct locusID, gsdbID, osymbol, ratmapID
from #llsymbols
group by locusID
having count(*) > 1
union
select distinct locusID, gsdbID, osymbol, ratmapID
from #llsymbols
where ratmapID is not null
group by ratmapID
having count(*) > 1
union
select distinct locusID, gsdbID, osymbol, ratmapID
from #llsymbols
group by osymbol
having count(*) > 1
order by osymbol
go

/* duplicate rat symbols in MGD */

select _Marker_key, symbol
into #markers
from MRK_Marker
where _Organism_key = ${RATSPECIESKEY}
go

insert into ${RADARDB}..WRK_LLMGIRatDuplicates
select *
from #markers
group by symbol having count(*) > 1
go

drop table #markers
go

/* add to WRK_LLRatLLIDsToAdd all records w/ neither a LL ID nor a RGD ID and: */
/*	1. match to LL Official or Interim symbol */
/*	2. mRNA Seq ID in common between MGD and LL */
/*      3. match to MGD via RatMap ID  (one-time only) */
/*	                                               */
/*      1. match to LL Interim if symbol like 'LOC%'   */

/* first, select all rat markers w/ neither LL ID nor RGD ID */
select m._Marker_key, m.symbol
into #nonoset
from MRK_Marker m
where m._Organism_key = ${RATSPECIESKEY}
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALRGDKEY})
go

delete #nonoset
from #nonoset m
where exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
or exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
go

select m._Marker_key, l.locusID, l.osymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
into #markers
from #nonoset m, ${RADARDB}..DP_LL l
where m.symbol = l.osymbol
and l.taxID = ${RATTAXID}
union
select m._Marker_key, l.locusID, l.isymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from #nonoset m, ${RADARDB}..DP_LL l
where m.symbol = l.isymbol
and l.osymbol is NULL
and l.taxID = ${RATTAXID}
go

/* add to WRK_LLRatLLIDsToAdd all records w/ no LL ID but a RGD ID or RatMap ID */

insert into ${RADARDB}..WRK_LLRatLLIDsToAdd
select m.*
from #markers m, ${RADARDB}..DP_LLAcc a, MRK_Acc_View ma
where m.locusID = a.locusID
and a.genbankID not like "NM%"
and a.seqType = "m"
and a.genbankID = ma.accID
and ma._Object_key = m._Marker_key
union
select m.*
from #markers m
where m.osymbol like "LOC%"
union
select m._Marker_key, l.locusID, l.osymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALRGDKEY}
and l.taxID = ${RATTAXID}
and l.osymbol is not null
and a.accID = l.gsdbID
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
union
select m._Marker_key, l.locusID, l.isymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALRGDKEY}
and l.taxID = ${RATTAXID}
and l.osymbol is null
and a.accID = l.gsdbID
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
union
select m._Marker_key, l.locusID, l.osymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALRGDKEY}
and l.taxID = ${RATTAXID}
and m.symbol = l.osymbol
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
union
select m._Marker_key, l.locusID, l.osymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALRATMAPKEY}
and a.accID = convert(varchar(30), l.mim)
and l.taxID = ${RATTAXID}
and l.osymbol is not NULL
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
union
select m._Marker_key, l.locusID, l.isymbol, l.gsdbID, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALRATMAPKEY}
and a.accID = convert(varchar(30), l.mim)
and l.taxID = ${RATTAXID}
and l.osymbol is NULL
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALLLKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
go

/* add to WRK_LLRatRGDIDsToAdd all records from WRK_LLRatLLIDsToAdd which have RGD IDs */
/* add to WRK_LLRatRGDIDsToAdd all records w/ LL ID and no RGD ID */

insert into ${RADARDB}..WRK_LLRatRGDIDsToAdd
select m._Marker_key, m.gsdbID
from ${RADARDB}..WRK_LLRatLLIDsToAdd m
where m.gsdbID is not null
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALRGDKEY})
union
select m._Marker_key, l.gsdbID
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.locusID
and l.taxID = $RATTAXID
and l.gsdbID is not null
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALRGDKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
go

/* add to WRK_LLRatRATMAPIDsToAdd all records from WRK_LLRatLLIDsToAdd which have RatMap IDs */
/* add to WRK_LLRatRATMAPIDsToAdd all records w/ LL ID and no RatMap ID */

insert into ${RADARDB}..WRK_LLRatRATMAPIDsToAdd
select m._Marker_key, m.ratmapID
from ${RADARDB}..WRK_LLRatLLIDsToAdd m
where m.ratmapID is not null
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALRATMAPKEY})
union
select m._Marker_key, ratmapID = convert(varchar(30), l.mim)
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.locusID
and l.taxID = $RATTAXID
and l.mim is not null
and not exists (select 1 from MRK_Acc_View ma
where m._Marker_key = ma._Object_key
and ma._LogicalDB_key = ${LOGICALRATMAPKEY})
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where m.symbol = d.osymbol)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
go

/* add to WRK_LLRatNomenUpdates all records w/ LL and Nomenclature Updates */

insert into ${RADARDB}..WRK_LLRatNomenUpdates
select m._Marker_key, m.symbol, m.name, l.osymbol, lname = l.name, type = "O"
from ${RADARDB}..WRK_LLRatLLIDsToAdd ml, MRK_Marker m, ${RADARDB}..DP_LL l
where ml._Marker_key = m._Marker_key
and ml.locusID = l.locusID
and l.osymbol is not null
and (m.symbol != l.osymbol or m.name != l.name)
union
select m._Marker_key, m.symbol, m.name, l.isymbol, lname = l.name, type = "I"
from ${RADARDB}..WRK_LLRatLLIDsToAdd ml, MRK_Marker m, ${RADARDB}..DP_LL l
where ml._Marker_key = m._Marker_key
and ml.locusID = l.locusID
and l.osymbol is null
and (m.symbol != l.isymbol or m.name != l.name)
union
select m._Marker_key, m.symbol, m.name, l.osymbol, lname = l.name, type = "O"
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.locusID
and l.osymbol is not null
and (m.symbol != l.osymbol or m.name != l.name)
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where a.accID = d.locusID)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
union
select m._Marker_key, m.symbol, m.name, l.isymbol, lname = l.name, type = "I"
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.locusID
and l.osymbol is null
and l.isymbol is not null
and (m.symbol != l.isymbol or m.name != l.name)
and not exists (select 1 from ${RADARDB}..WRK_LLRatDuplicates d
where a.accID = d.locusID)
and not exists (select 1 from ${RADARDB}..WRK_LLMGIRatDuplicates d
where m.symbol = d.symbol)
order by symbol
go

insert into ${RADARDB}..WRK_LLRatMappingUpdates
select m._Marker_key, m.symbol, m.chromosome, m.cytogeneticOffset, l.chromosome, l.offset, l.locusID
from ${RADARDB}..WRK_LLRatLLIDsToAdd ml, MRK_Marker m, ${RADARDB}..DP_LL l
where ml._Marker_key = m._Marker_key
and m._Organism_key = ${RATSPECIESKEY}
and ml.locusID = l.locusID
union
select m._Marker_key, m.symbol, m.chromosome, m.cytogeneticOffset, l.chromosome, l.offset, l.locusID
from MRK_Marker m, MRK_Acc_View a, ${RADARDB}..DP_LL l
where m._Organism_key = ${RATSPECIESKEY}
and m._Marker_key = a._Object_key
and a._LogicalDB_key = ${LOGICALLLKEY}
and a.accID = l.locusID
go

/* convert the LL offset values to MGI format (remove the leading chromosome value) */

update ${RADARDB}..WRK_LLRatMappingUpdates
set llOff = substring(llOff, 3, 100)
where llOff like '[12][0-9]%'
go

update ${RADARDB}..WRK_LLRatMappingUpdates
set llOff = substring(llOff, 2, 100)
where llOff like '[1-9]%'
or llOff like '[xy]%'
go

update ${RADARDB}..WRK_LLRatMappingUpdates
set llOff = NULL
where llOff like '[1-9]'
go

update ${RADARDB}..WRK_LLRatMappingUpdates
set llChr = "MT", llOff = NULL
where llChr = "mitochon"
go

update ${RADARDB}..WRK_LLRatMappingUpdates set llChr = 'UN' where llChr is null
go

delete from ${RADARDB}..WRK_LLRatMappingUpdates
where llChr = "MT" or
llChr = null or
(mgiChr = llChr and mgiOff = llOff)
or
(mgiChr = llChr and llOff = null)
go

quit
 
EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Rat_create.logical >>& ${LOG}

# permissions
${RADARDBPERMSDIR}/public/table/WRK_LL_Rat_grant.logical >>& ${LOG}

date >> $LOG
echo "Finished creating Rat Temp Tables." >> $LOG
