#!/bin/csh -fx

#
# Common Load
#
# Usage:  commonload.csh
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

cd `dirname $0` && source ./Configuration

setenv DATADIR $1
setenv ARCHIVEDIR $2
setenv TAXID $3
setenv SPECIESKEY $4
setenv SYNTYPEKEY $5

archive.csh ${DATADIR} ${ARCHIVEDIR}

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

deleteIDs.csh ${DATADIR} ${SPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "" ${SYNTYPEKEY}
createSets.csh ${DATADIR} ${TAXID} ${SPECIESKEY}
commonBuckets-1.csh ${DATADIR} ${TAXID} ${SPECIESKEY}
commonBuckets-2.csh ${DATADIR} ${TAXID}
acc.csh ${DATADIR} ${TAXID} ${SPECIESKEY}
syns.csh ${DATADIR} ${TAXID} ${SYNTYPEKEY}
updateNomen.csh ${DATADIR} ${TAXID} ${SPECIESKEY}
updateMapping.csh ${DATADIR} ${TAXID}
deleteObsolete.csh ${DATADIR} ${TAXID} ${SPECIESKEY}
runreports.csh ${DATADIR}

date >> ${LOG}
