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

# truncate table
${RADARDBSCHEMADIR}/table/WRK_EntrezGene_Bucket0_truncate.object | tee -a ${LOG}

# drop indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object | tee -a ${LOG}

cat - <<EOSQL | doisql.csh $0 | tee -a ${LOG}
 
use ${RADARDB}
go

/* set of matches by id and idType */
/* must match on 2 id types, MGI and Gen */

select s1.geneID, s2.mgiID
into #matches1
from WRK_EntrezGene_EGSet s1, WRK_EntrezGene_MGISet s2
where s1.taxID = ${MOUSETAXID}
and s1.idType = 'MGI'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${MOUSETAXID}
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
and s1.taxID = ${MOUSETAXID}
and u1.mgiID = s2.mgiID
and s1.idType = 'Gen'
and s1.compareID = s2.compareID
and s1.idType = s2.idType
and s2.taxID = ${MOUSETAXID}
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
/* for this algorithm, we are only interested in 1:1 */

/* EntrezGene (1), MGI (1) */
select u.geneID, u.mgiID
into #bucket0
from #uniqmatches2 u
group by geneID having count(*) = 1
go

create index idx1 on #bucket0(mgiID)
create index idx2 on #bucket0(geneID)
go

/* EG ids */

insert into WRK_EntrezGene_Bucket0
select distinct ${MOUSETAXID}, a._Object_key, ${LOGICALEGKEY}, b.mgiID, b.geneID, ${MOUSEEGPRIVATE}, 1
from #bucket0 b, ${DBNAME}..ACC_Accession a
where b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
go

/* RefSeq ids */

insert into WRK_EntrezGene_Bucket0
select distinct ${MOUSETAXID}, a._Object_key, ${LOGICALREFSEQKEY}, b.mgiID, r.rna, ${REFSEQPRIVATE}, 1
from #bucket0 b, ${DBNAME}..ACC_Accession a, DP_EntrezGene_RefSeq r
where b.mgiID = a.accID
and a._MGIType_key = ${MARKERTYPEKEY}
and b.geneID = r.geneID
and r.rna like 'NM_%'
go

/* Additional mRNA GenBank IDs */

insert into WRK_EntrezGene_Bucket0
select ${MOUSETAXID}, a._Object_key, ${LOGICALSEQKEY}, b.mgiID, r.rna, ${MOUSEEGPRIVATE}, 1
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

EOSQL
 
# create indexes
${RADARDBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object | tee -a ${LOG}

date | tee -a ${LOG}
echo "End: creating mouse buckets." | tee -a ${LOG}
