#!/bin/csh -fx

#
# Create Exclude Buckets for Mouse Processing
#
# Usage:  createExclude.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating mouse exclude buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

# truncate tables
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_ExcludeA_truncate.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_ExcludeB_truncate.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_ExcludeC_truncate.object | tee -a ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeA_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeB_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeC_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${DBNAME}
go

/***** MGI *****/

/* Get Unique Sequence/Marker pairs */

select distinct _Sequence_key, _Marker_key
into #mgi1
from SEQ_Marker_Cache
go

create index idx1 on #mgi1(_Sequence_key)
create index idx2 on #mgi1(_Marker_key)
go

/* GenBank sequences in MGI associated w/ 1 mouse marker */

select _Sequence_key, _Marker_key
into #mgisingle1
from #mgi1
group by _Sequence_key having count(*) = 1
go

create index idx1 on #mgisingle1(_Sequence_key)
create index idx2 on #mgisingle1(_Marker_key)
go

/* Resolve Sequence ID, Marker ID for single markers */

select seqID = a1.accID, mgiID = a2.accID
into #mgisingle2
from #mgisingle1 s, ACC_Accession a1, ACC_Accession a2
where s._Sequence_key = a1._Object_key
and a1._MGIType_key = 19
and a1.preferred = 1
and s._Marker_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = 1
and a2.prefixPart = "MGI:"
and a2.preferred = 1
go

create index idx1 on #mgisingle2(seqID)
create index idx2 on #mgisingle2(mgiID)
go

/* GenBank sequences in MGI associated w/ multiple mouse markers */

select _Sequence_key, _Marker_key
into #mgimult1
from #mgi1
group by _Sequence_key having count(*) > 1
go

create index idx1 on #mgimult1(_Sequence_key)
create index idx2 on #mgimult1(_Marker_key)
go

/* Resolve Sequence ID, Marker ID for multiple markers */

select seqID = a1.accID, mgiID = a2.accID
into #mgimult2
from #mgimult1 s, ACC_Accession a1, ACC_Accession a2
where s._Sequence_key = a1._Object_key
and a1._MGIType_key = 19
and a1.preferred = 1
and s._Marker_key = a2._Object_key
and a2._MGIType_key = ${MARKERTYPEKEY}
and a2._LogicalDB_key = 1
and a2.prefixPart = "MGI:"
and a2.preferred = 1
go

create index idx1 on #mgimult2(seqID)
create index idx2 on #mgimult2(mgiID)
go

/* Problem Molecular Segments and their GenBank Sequences */

select n._Probe_key, mgiID = pa.accID
into #probes1 
from PRB_Notes n, ACC_Accession pa
where n.note like "%staff have found evidence of artifact in the sequence of this molecular%"
and n._Probe_key = pa._Object_key
and pa._MGIType_key = ${PROBETYPEKEY}
and pa._LogicalDB_key = 1
and pa.prefixPart = "MGI:"
and pa.preferred = 1

go

create index idx1 on #probes1(_Probe_key)
go

select distinct p._Probe_key, p.mgiID, seqID = a.accID
into #probes2
from #probes1 p, ACC_Accession a 
where p._Probe_key = a._Object_key  
and a._LogicalDB_key = ${LOGICALSEQKEY}
and a._MGIType_key = ${PROBETYPEKEY}
go

create index idx1 on #probes2(_Probe_key)
create index idx2 on #probes2(mgiID)
go

/****** Exclude A *****/
/* EntrezGene IDs which map to Markers which are not Genes or Pseudogenes */

insert into ${RADARDB}..WRK_EntrezGene_ExcludeA
select distinct e.locusTag, e.geneID
from ${RADARDB}..DP_EntrezGene_Info e, ACC_Accession a, MRK_Marker m
where e.taxID = ${MOUSETAXID}
and e.locusTag = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and a._Object_key = m._Marker_key
and m._Marker_Type_key not in (1,7)
go

/***** Exclude B *****/
/* 1.  EntrezGene Seq IDs associated with > 1 Marker in MGI */
/* 2.  Seq IDs associated with a Molecular Segment that contains the "problem sequence" note (see TR 2951)  */

/* GenBank sequences in EntrezGene that resolve to > 1 MGI Marker */

insert into ${RADARDB}..WRK_EntrezGene_ExcludeB
select m.seqID, m.mgiID, e.geneID
from #mgimult2 m, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.rna = m.seqID
go

insert into ${RADARDB}..WRK_EntrezGene_ExcludeB
select m.seqID, m.mgiID, e.geneID
from #mgimult2 m, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.genomic = m.seqID
go

insert into ${RADARDB}..WRK_EntrezGene_ExcludeB
select p.seqID, p.mgiID, e.geneID
from #probes2 p, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.rna = p.seqID
go

insert into ${RADARDB}..WRK_EntrezGene_ExcludeB
select p.seqID, p.mgiID, e.geneID
from #probes2 p, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.genomic = p.seqID
go

/***** Exclude C *****/
/* EntrezGene records that resolve to > 1 MGI Marker */

select s.seqID, s.mgiID, e.geneID
into #egToMGI1
from #mgisingle2 s, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.rna = s.seqID
go

insert into #egToMGI1
select s.seqID, s.mgiID, e.geneID
from #mgisingle2 s, ${RADARDB}..DP_EntrezGene_Info e, ${RADARDB}..DP_EntrezGene_Accession ea
where e.taxID = ${MOUSETAXID}
and e.geneID = ea.geneID
and ea.genomic = s.seqID
go

create index idx1 on #egToMGI1(geneID)
go

select distinct mgiID, geneID into #egToMGI2 from #egToMGI1
go

create index idx1 on #egToMGI2(geneID)
go

insert into ${RADARDB}..WRK_EntrezGene_ExcludeC
select mgiID, geneID
from #egToMGI2
group by geneID having count(*) > 1
go

quit
 
EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeA_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeB_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_ExcludeC_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating mouse exclude buckets." | tee -a ${LOG}
