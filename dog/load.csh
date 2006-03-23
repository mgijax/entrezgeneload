#!/bin/csh -fx

#
# Process Dog Updates
#
# Usage:  load.csh
#
# Processing
#
#	1.  Delete all dog RefSeq and synonyms
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

cd `dirname $0` && source ../Configuration

../archive.csh ${DOGDATADIR} ${DOGARCHIVEDIR}

setenv LOG      ${DOGDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteIDs.csh ${DOGDATADIR} ${DOGSPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "" ${DOGSYNTYPEKEY}

#
#
#

../createSets.csh ${DOGDATADIR} ${DOGTAXID} ${DOGSPECIESKEY}
./createBuckets.csh
../acc.csh ${DOGDATADIR} ${DOGTAXID} ${DOGSPECIESKEY}
../syns.csh ${DOGDATADIR} ${DOGTAXID} ${DOGSYNTYPEKEY}
../updateNomen.csh ${DOGDATADIR} ${DOGTAXID} ${DOGSPECIESKEY}
../updateMapping.csh ${DOGDATADIR} ${DOGTAXID}
../deleteObsolete.csh ${DOGDATADIR} ${DOGTAXID} ${DOGSPECIESKEY}
../runreports.csh ${DOGDATADIR}

date >> ${LOG}
