#!/bin/csh -fx

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
#	Delete obsolete Marker records
#	Run reports
#
# History
#

setenv LOG      ${DATADIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/dog/load.csh/acc.csh
${ENTREZGENELOAD}/dog/load.csh/syns.csh
${ENTREZGENELOAD}/dog/load.csh/updateNomen.csh
${ENTREZGENELOAD}/dog/load.csh/updateMapping.csh
${ENTREZGENELOAD}/dog/load.csh/deleteObsolete.csh
${ENTREZGENELOAD}/dog/load.csh/runreports.csh

date >> ${LOG}
