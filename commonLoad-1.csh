#!/bin/csh -fx

#
# Common Load
#
# Usage:  commonLoad-1.csh
#
# Processing
#
#	Archive previous logs and output files
#	Delete all previously loaded associations
#	Create EG and MGI Sets in RADAR
#	Create Buckets in RADAR
#	Load Marker and Accession records
#	Load Synonyms
#	Update Nomenclature information (symbol, name)
#	Update Mapping information (chromosome, map position)
#	Delete obsolete Marker records
#	Run reports
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
