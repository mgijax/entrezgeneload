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

${ENTREZGENELOAD}/archive.csh ${DATADIR} ${ARCHIVEDIR}

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/deleteIDs.csh
${ENTREZGENELOAD}/createSets.csh
${ENTREZGENELOAD}/commonBuckets-1.csh
${ENTREZGENELOAD}/commonBuckets-2.csh
${ENTREZGENELOAD}/acc.csh
${ENTREZGENELOAD}/syns.csh
${ENTREZGENELOAD}/updateNomen.csh
${ENTREZGENELOAD}/updateMapping.csh
${ENTREZGENELOAD}/deleteObsolete.csh
${ENTREZGENELOAD}/runreports.csh

date >> ${LOG}
