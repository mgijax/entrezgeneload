#!/bin/csh -fx

#
# Create Buckets for Mouse Processing
#
# Usage:  createBuckets.sh
#
# History
#

cd `dirname $0` && source ../Configuration

setenv LOG      ${MOUSEDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: creating mouse buckets..." | tee -a ${LOG}
date | tee -a ${LOG}

# truncate tables
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_Bucket0_truncate.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_Bucket10_truncate.object | tee -a ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket10_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

/* set of matches by id and idType */
/* must match on 2 id types, MGI and Gen */

select s1.geneID, s2.mgiID
into #matches1
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.idType = 'MGI'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
go

create index idx1 on #matches1(geneID)
create index idx2 on #matches1(mgiID)
go

/* unique matches by id and idType */

select distinct geneID, mgiID
into #uniqmatches1
from #matches1
go

create index idx1 on #uniqmatches1(geneID)
create index idx2 on #uniqmatches1(mgiID)
go

/* must match on Gen too */

select s1.geneID, s2.mgiID
into #matches2
from #uniqmatches1 u1, WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where u1.geneID = s1.geneID
and u1.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
go

create index idx1 on #matches2(geneID)
create index idx2 on #matches2(mgiID)
go

/* unique matches by id and idType */

select distinct geneID, mgiID
into #uniqmatches2
from #matches2
go

create index idx1 on #uniqmatches2(geneID)
create index idx2 on #uniqmatches2(mgiID)
go

/*** Bucketizing ***/
/* for this algorithm, we are only interested in 1:1 and 1:N (aka Bucket 10) */

/* EntrezGene (?), MGI (N) */
select geneID, mgiID
into #s1N
from #uniqmatches2
group by geneID having count(*) > 1
go

create index idx1 on #s1N(geneID)
create index idx2 on #s1N(mgiID)
go

/* EntrezGene (N), MGI (?) */
select geneID, mgiID
into #s2N
from #uniqmatches2
group by mgiID having count(*) > 1
go

create index idx1 on #s2N(geneID)
create index idx2 on #s2N(mgiID)
go

/* EntrezGene (1), MGI (1) */
select u.geneID, u.mgiID
into #bucket0
from #uniqmatches2 u
where not exists (select 1 from #s1N s where u.geneID = s.geneID)
and not exists (select 1 from #s2N s where u.mgiID = s.mgiID)
go

create index idx1 on #bucket0(mgiID)
create index idx2 on #bucket0(geneID)
go

/* EntrezGene (N), MGI (N) */
select distinct eg1 = s1.geneID, mgi1 = s1.mgiID, eg2 = s2.geneID, mgi2 = s2.mgiID
into #bucket5 
from #s1N s1, #s2N s2 
where s1.geneID = s2.geneID
or s1.mgiID = s2.mgiID
go

create index idx1 on #bucket5(eg1)
create index idx2 on #bucket5(mgi1)
create index idx3 on #bucket5(eg2)
create index idx4 on #bucket5(mgi2)
go

/* EntrezGene (1), MGI (N) */
select distinct geneID, mgiID
into #bucket10
from #s1N s
where not exists (select 1 from #bucket5 t where s.geneID = t.eg1)
and not exists (select 1 from #bucket5 t where s.mgiID = t.mgi1)
and not exists (select 1 from #bucket5 t where s.geneID = t.eg2)
and not exists (select 1 from #bucket5 t where s.mgiID = t.mgi2)
go

create index idx1 on #bucket10(mgiID)
create index idx2 on #bucket10(geneID)
go

/* EG ids */

insert into WRK_EntrezGene_Bucket0
select distinct a._Object_key, ${LOGICALEGKEY}, b.mgiID, b.geneID, ${MOUSEEGPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a
where b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
go

/* RefSeq ids */

insert into WRK_EntrezGene_Bucket0
select distinct a._Object_key, ${LOGICALREFSEQKEY}, b.mgiID, r.rna, ${REFSEQPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/* Additional mRNA GenBank IDs */

insert into WRK_EntrezGene_Bucket0
select a._Object_key, ${LOGICALSEQKEY}, b.mgiID, r.rna, ${MOUSEEGPRIVATE}
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_Accession r
where b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and b.geneID = r.geneID
and r.rna != '-'
and r.rna not like 'N%_%'
and r.rna not like 'X%_%'
and not exists (select 1 from ${DBNAME}..ACC_Accession ma 
where a._Object_key = ma._Object_key
and ma._MGIType_key = ${MARKERTYPEKEY}
and ma._LogicalDB_key = ${LOGICALSEQKEY}
and r.rna = ma.accID)
go

/*insert into WRK_EntrezGene_Bucket10 */
/*select distinct b.geneID, e.symbol, b.mgiID, b.uID */
/*from #bucket10 b, DP_EntrezGene_Info e */
/*where b.geneID = e.geneID */
/*go */

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object | tee -a ${LOG}
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket10_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating mouse buckets." | tee -a ${LOG}
