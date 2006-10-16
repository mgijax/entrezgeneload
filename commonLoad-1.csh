#!/bin/csh -fx

#
# Common Load
#
# Usage:  commonLoad-1.csh
#
# Processing
#
#	1.  Delete all RefSeq and synonyms
#	2.  Create EG and MGI Sets in RADAR.
#	3.  Create Buckets in RADAR.
#	4.  Load Marker and Accession records.
#	5.  Load Synonyms.
#	6.  Update Nomenclature information (symbol, name).
#	7.  Update Mapping information (chromosome, map position).
#	8.  Delete obsolete Marker records.
#	9.  Run reports.
#
# History
#

archive.csh ${DATADIR} ${ARCHIVEDIR}

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

deleteIDs.csh
createSets.csh
commonBuckets-1.csh
commonBuckets-2.csh
acc.csh
syns.csh
updateNomen.csh
updateMapping.csh
deleteObsolete.csh
runreports.csh

date >> ${LOG}
