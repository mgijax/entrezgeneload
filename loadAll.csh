#!/bin/csh -fx

#
# Program:
#	loadAll.csh
#
# Original Author:
#	Lori Corbani
#
# Purpose:
#	Wrapper to execute all EntrezGene loads (human, rat)
#
# Modification History:
#
#
# 05/24/2005 - lec
#	- TR 6046; removing mouse....mouse load is now done by the "egload" product
#
# 01/03/2004 - lec
#	- TR 5939/LocusLink->EntrezGene conversion
#

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date >> ${LOG}

${ENTREZGENELOAD}/updateIDs.csh >> ${LOG}
${ENTREZGENELOAD}/human/load.csh >> ${LOG}
${ENTREZGENELOAD}/rat/load.csh >> ${LOG}
${ENTREZGENELOAD}/dog/load.csh >> ${LOG}
${ENTREZGENELOAD}/chimpanzee/load.csh >> ${LOG}

# run general reports

setenv REPORTSDIR ${ENTREZGENELOAD}/reports
setenv DATADIR ${EGOUTPUTDIR}
${ENTREZGENELOAD}/runreports.csh >> ${LOG}

date >> ${LOG}
