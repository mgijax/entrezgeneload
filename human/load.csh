#!/bin/csh -fx

#
# Process Human Updates
#
# Usage:  load.csh
#
# History
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

../deleteOrphans.csh ${HUMANDATADIR} ${HUMANSPECIESKEY}
../deleteIDs.csh ${HUMANDATADIR} ${HUMANSPECIESKEY} ${LOGICALREFSEQKEY} ${LOGICALHGNCKEY} ${HUMSYNTYPEKEY}
../createSets.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
./createBuckets.csh
../runreports.csh ${HUMANDATADIR}
../acc.csh ${HUMANDATADIR} ${HUMANTAXID}
../syns.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMSYNTYPEKEY}
../updateNomen.csh ${HUMANDATADIR} ${HUMANTAXID} ${HUMANSPECIESKEY}
../updateMapping.csh ${HUMANDATADIR} ${HUMANTAXID}

date >> ${LOG}
