#!/bin/csh -fx

#
# Create Work Tables for processing Mouse data
#
# Usage:  createWorkFiles.sh
#
# History
#	03/19/2002	lec
#	- TR 3461; exclude Problem Seq ID fix
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Creating Mouse Work Tables..." >> ${LOG}
date >> ${LOG}

# truncate tables
${RADARDBSCHEMADIR}/table/WRK_LL_Mouse_truncate.logical >>& ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Mouse_drop.logical >>& ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

/* create table of: */
/* EntrezGene IDs which map to Markers which are not Genes or Pseudogenes */

insert into ${RADARDB}..WRK_LLExcludeNonGenes
select distinct a._Object_key, m._Marker_Type_key, l.geneID, l.locusTag
from ${RADARDB}..DP_EntrezGene_Info l, ACC_Accession a, MRK_Marker m
where l.taxID = ${MOUSETAXID}
and l.locusTag = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = m._Marker_key
and m._Marker_Type_key not in (1,7)
go

/* select all seq IDs for mouse */

select distinct a._Object_key, a._MGIType_key, a.accID, la.geneID
into #seqIDs
from ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc la, ACC_Accession a
where l.taxID = ${MOUSETAXID}
and l.geneID = la.geneID
and la.genbankID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
go

/* create table of: */
/* EntrezGene IDs/Seq IDs to exclude from mouse processing */
/* because the same Seq ID is associated w/ > 1 Marker in MGI */

insert into ${RADARDB}..WRK_LLExcludeSeqIDs
select * from #seqIDs
group by accID having count(*) > 1
go

/* EntrezGene IDs to exclude from mouse processing because: */
/* all EntrezGene IDs which contain Seq IDs which are associated with Molecular Segments */
/* which contain the "problem sequence" note (see TR 2951)  */

select _Probe_key 
into #probes 
from PRB_Notes 
where note like "%staff have found evidence of artifact in the sequence of this molecular%"
go

/* Select probes w/ Seq IDs */
select distinct p._Probe_key, a.accID
into #probeseqs 
from #probes p, ACC_Accession a 
where p._Probe_key = a._Object_key  
and a._LogicalDB_key = ${LOGICALSEQKEY}
and a._MGIType_key = 3
go

select distinct a._Object_key, a._MGIType_key, a.accID, la.geneID
into #problemseqIDs
from #probeseqs d, ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc la, ACC_Accession a
where l.taxID = ${MOUSETAXID}
and l.geneID = la.geneID
and la.genbankID = a.accID
and a._MGIType_key = ${PROBETYPEKEY}
and a._Object_key = d._Probe_key
go

/* insert records int..WRK_LLExcludeSeqIDs*/

insert into ${RADARDB}..WRK_LLExcludeSeqIDs
select * from #problemseqIDs
go

/* create table to exclude from mouse processing because: */
/* a) the EntrezGene IDs contain different Seq IDs which are associated */
/*    with more than 1 Marker in MGI */

/* remove records which already exist i..WRK_LLExcludeSeqIDs */

delete #seqIDs
from #seqIDs s, ${RADARDB}..WRK_LLExcludeSeqIDs e
where s.geneID = e.geneID
and s.accID = e.accID
go

/* get distinc..WRK_LL/MGI records */

select distinct _Object_key, geneID
into #seqIDs2
from #seqIDs
go

/* select those where the EntrezGene record maps to > 1 MGI record */

insert into ${RADARDB}..WRK_LLExcludeLLIDs
select *
from #seqIDs2
group by geneID having count(*) > 1
go

insert into ${RADARDB}..WRK_LLBucket0
select distinct m._Object_key, ${LOGICALLLKEY}, m.accID, l.geneID, ${MOUSELLPRIVATE}
from ACC_Accession m, ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc la, ACC_Accession a2
where m._MGIType_key = 2
and m.prefixPart = "MGI:"
and m.preferred = 1
and m.accID = l.locusTag
and l.taxID = ${MOUSETAXID}
and l.geneID = la.geneID
and la.genbankID = a2.accID
and a2._LogicalDB_key = ${LOGICALSEQKEY}
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._Object_key = m._Object_key
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeNonGenes e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeSeqIDs e
where l.geneID = e.geneID
and a2.accID = e.accID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeLLIDs e
where l.geneID = e.geneID)
go

/* EntrezGene */

insert into ${RADARDB}..WRK_LLBucket0
select distinct m._Object_key, ${LOGICALENTREZGENEKEY}, m.accID, l.geneID, ${MOUSELLPRIVATE}
from ACC_Accession m, ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc la, ACC_Accession a2
where m._MGIType_key = 2
and m.prefixPart = "MGI:"
and m.preferred = 1
and m.accID = l.locusTag
and l.taxID = ${MOUSETAXID}
and l.geneID = la.geneID
and la.genbankID = a2.accID
and a2._LogicalDB_key = ${LOGICALSEQKEY}
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._Object_key = m._Object_key
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeNonGenes e
where l.geneID = e.geneID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeSeqIDs e
where l.geneID = e.geneID
and a2.accID = e.accID)
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeLLIDs e
where l.geneID = e.geneID)
go

/* RefSeq */

insert into ${RADARDB}..WRK_LLBucket0
select distinct l._Object_key, ${LOGICALREFSEQKEY}, l.accID, lr.rna, ${REFSEQPRIVATE}
from ${RADARDB}..WRK_LLBucket0 l, ${RADARDB}..DP_EntrezGene_RefSeq lr
where l.llaccID = lr.geneID
and lr.rna like 'NM%'
go

/* Bucket 10..WRK_LL Mouse Symbols w/ Unpublished GenBank ID; GenBank ID Not Attached to MGI Marker */
/* MGC records (acc ID begins 'BC%') from this bucket will be used to feed records into Nomen */

select distinct l.geneID
into #matchFound
from ${RADARDB}..DP_LLAcc l, ACC_Accession a
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = ${LOGICALSEQKEY}
and a.accID = l.genbankID
and not exists (select 1 from ${RADARDB}..WRK_LLExcludeNonGenes e
where l.geneID = e.geneID)
go
 
create nonclustered index index_geneID on #matchFound(geneID)
go

/* select unpublished... */
/* */
/* select all locus link records for which none of its non-genomic genbank ids can be found attached */
/* to an MGI Marker or an MGI Probe */
/* */

insert into ${RADARDB}..WRK_LLBucket10
select l.geneID, l.symbol, l.locusTag, a.genbankID, printGB = a.genbankID
from ${RADARDB}..DP_EntrezGene_Info l, ${RADARDB}..DP_LLAcc a
where l.taxid = ${MOUSETAXID}
and l.geneID = a.geneID
and a.genbankID not like "NM%"
and a.genbankID not like "CAAA%"
and a.seqType != "g"
and not exists (select 1 from #matchFound m
where l.geneID = m.geneID)
and not exists (select 1 from ACC_Accession ma
where ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALSEQKEY}
and ma.accID = a.genbankID)
and not exists (select 1 from ACC_Accession ma
where ma._MGIType_key = ${PROBETYPEKEY}
and ma._LogicalDB_key = ${LOGICALSEQKEY}
and ma.accID = a.genbankID)
and not exists (select 1 from ${RADARDB}..DP_EntrezGene_PubMed c
where l.geneID = c.geneID)
go

quit
 
EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_LL_Mouse_create.logical >>& ${LOG}

# permissions
${RADARDBPERMSDIR}/public/table/WRK_LL_Mouse_grant.logical >>& ${LOG}

date >> ${LOG}
echo "Finished creating Mouse Work Tables." >> ${LOG}
