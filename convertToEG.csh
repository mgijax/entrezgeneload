#!/bin/csh -fx

# $Header$
# $Name$

#
# Program:
#	convertToEG.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Convert LocusLink logical DB keys to EntrezGene
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
#

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: conversion from LocusLink to EG..." >> ${LOG}
date >> ${LOG}

cat - <<EOSQL | doisql.csh $0 >>& ${LOG}
 
use ${DBNAME}
go

select a._Accession_key
into #toupdate
from ACC_Accession a, MRK_Marker m 
where a._MGIType_key = ${MARKERTYPEKEY}
and a._LogicalDB_key = 24
and a._Object_key = m._Marker_key
and m._Organism_key != ${MOUSESPECIESKEY}
go

create index idx1 on #toupdate(_Accession_key)
go

update ACC_Accession
set _LogicalDB_key = ${LOGICALEGKEY}
from #toupdate u, ACC_Accession a
where u._Accession_key = a._Accession_key
go

/* remove GDB ids from MGI */

select a._Accession_key
into #todelete
from ACC_Accession a
where a._LogicalDB_key = 2
go

create index idx1 on #todelete(_Accession_key)
go

delete ACC_Accession
from #todelete d, ACC_Accession a
where d._Accession_key = a._Accession_key
go

delete from ACC_ActualDB where _LogicalDB_key = 2
go

delete from ACC_LogicalDB where _LogicalDB_key = 2
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: conversion from LocusLink to EG." >> ${LOG}
