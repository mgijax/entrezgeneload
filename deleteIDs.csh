#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	deleteIDs.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Delete Marker/ID associations for given Organism
#
# Requirements Satisfied by This Program:
#
# Usage:
#
# Envvars:
#
# Inputs:
#
# Outputs:
#
# Exit Codes:
#
# Assumes:
#
# Bugs:
#
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 01/03/2005 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

setenv DATADIR $1
setenv ORGANISM $2
setenv LOGICALDBBYREF $3
setenv LOGICALDB $4
setenv SYNTYPEKEY $5

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: deleting Marker/ID associations..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

/* remove existing assocations by reference */

select a._Accession_key
into #todelete
from ACC_Accession a, ACC_AccessionReference r, MRK_Marker m 
where r._Refs_key = ${REFERENCEKEY}
and r._Accession_key = a._Accession_key 
and a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key in (${LOGICALDBBYREF})
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
and a._LogicalDB_key in (${LOGICALDB})
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

quit
 
EOSQL
 
date >> ${LOG}
echo "End: deleting Marker/ID associations." >> ${LOG}
