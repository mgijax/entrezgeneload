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
# 01/03/2004 - lec
#

setenv DATADIR $1
setenv ORGANISM $2

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

echo "Begin: conversion..." >> ${LOG}
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
and m._Organism_key = ${ORGANISM}
go

create index idx1 on #toupdate(_Accession_key)
go

update ACC_Accession
set _LogicalDB_key = ${LOGICALEGKEY}
from #toupdate u, ACC_Accession a
where u._Accession_key = a._Accession_key
go

quit
 
EOSQL
 
date >> ${LOG}
echo "End: conversion." >> ${LOG}
