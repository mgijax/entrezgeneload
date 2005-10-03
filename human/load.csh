#!/bin/csh -fx

#
# Process Human Updates
#
# Usage:  load.csh
#
# Processing
#
#	1.  Delete all human RefSeq, HGNC and OMIM gene annotations, and synonyms
#	2.  Create EG and MGI Sets in RADAR.
#	3.  Create Buckets in RADAR.
#	4.  Run reports.
#	5.  Load Marker and Accession records.
#	6.  Load Synonyms.
#	7.  Update Nomenclature information (symbol, name).
#	8.  Update Mapping information (chromosome, map position).
#	9.  Delete/load Human/OMIM Disease Annotations
#	10. Delete obsolete Marker records.
#
# History
#
#	09/15/2005 lec
#	- TR 5972 - add load of SwissProt, NP, XP
#
#	04/28/2005 lec
#	- TR 3853, OMIM
#
#	12/15/2003 lec
#	- TR 5382; human refseqs
#
#	03/02/2001 lec
#	- TR 2265
#
#	12/07/2000 lec
#	- TR 1992
#

cd `dirname $0` && source ../Configuration

../archive.csh ${HUMANDATADIR} ${HUMANARCHIVEDIR}

setenv LOG      ${HUMANDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteIDs.csh ${HUMANDATADIR} ${HUMANSPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "${LOGICALHGNCKEY},${LOGICALOMIMKEY}" ${HUMSYNTYPEKEY}

#
# for PIRSF implementation only...this really only has to be run once
#
../deleteIDs.csh ${HUMANDATADIR} ${HUMANSPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "${LOGICALREFSEQKEY},${LOGICALSPKEY}" ${HUMSYNTYPEKEY}
#
#
#

../createSets.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
./createBuckets.csh
../runreports.csh ${HUMANDATADIR}
../acc.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
../syns.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMSYNTYPEKEY}
../updateNomen.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
../updateMapping.csh ${HUMANDATADIR} ${HUMANTAXID}
./annotations.csh ${HUMANDATADIR}
../deleteObsolete.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}

# done as part of rat...so let's not do it twice
#${DBUTILSBINDIR}/runDeleteObsoleteDummy.csh ${DBSERVER} ${DBNAME}
#${DBUTILSBINDIR}/runCreateDummy.csh ${DBSERVER} ${DBNAME}

date >> ${LOG}
