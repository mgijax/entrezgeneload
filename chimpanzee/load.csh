#!/bin/csh -fx

#
# Process Chimpanzee Updates
#
# Usage:  load.csh
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

cd `dirname $0` && source ../Configuration

../archive.csh ${CHIMPDATADIR} ${CHIMPARCHIVEDIR}

setenv LOG      ${CHIMPDATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

../deleteIDs.csh ${CHIMPDATADIR} ${CHIMPSPECIESKEY} "${LOGICALREFSEQKEY},${LOGICALSPKEY}" "" ${CHIMPSYNTYPEKEY}

#
#
#

../createSets.csh ${CHIMPDATADIR} ${CHIMPTAXID} ${CHIMPSPECIESKEY}
./createBuckets.csh
../acc.csh ${CHIMPDATADIR} ${CHIMPTAXID} ${CHIMPSPECIESKEY}
../syns.csh ${CHIMPDATADIR} ${CHIMPTAXID} ${CHIMPSYNTYPEKEY}
../updateNomen.csh ${CHIMPDATADIR} ${CHIMPTAXID} ${CHIMPSPECIESKEY}
../updateMapping.csh ${CHIMPDATADIR} ${CHIMPTAXID}
../deleteObsolete.csh ${CHIMPDATADIR} ${CHIMPTAXID} ${CHIMPSPECIESKEY}
../runreports.csh ${CHIMPDATADIR}

date >> ${LOG}
