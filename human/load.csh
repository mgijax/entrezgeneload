#!/bin/csh -f

#
# Process Human Updates
#
# Usage:  load.csh
#
# History
#
#       09/12/2013      lec
#       - TR11484/human/annotation.py/load.csh
#               a) load.csh : annotation.csh was turned OFF/turn back ON
#               b) mim-source "NULL" changed to "-"
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

cd `dirname $0` && source ../human.config

${ENTREZGENELOAD}/archive.csh

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/deleteIDs.csh
${ENTREZGENELOAD}/createSets.csh
${ENTREZGENELOAD}/human/createBuckets.csh
${ENTREZGENELOAD}/commonLoad-2.csh
${ENTREZGENELOAD}/human/annotations.csh

date >> ${LOG}
