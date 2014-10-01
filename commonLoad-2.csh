#!/bin/csh -f

#
# Common Load
#
# Usage:  commonLoad-2.csh
#
# Processing
#
#	Load Marker and Accession records
#	Load Synonyms
#	Update Nomenclature information (symbol, name)
#	Update Mapping information (chromosome, map position)
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/acc.csh
${ENTREZGENELOAD}/syns.csh
${ENTREZGENELOAD}/updateNomen.csh
${ENTREZGENELOAD}/updateMapping.csh

date >> ${LOG}
