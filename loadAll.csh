#!/bin/csh -f

#
# Program:
#	loadAll.csh
#
# Purpose:
#	Wrapper to execute all EntrezGene loads (human, rat)
#
# History
#
# 11/08/2023    lec
#       wts2-1324/fl2-625/egload pipeline issue/add sanity check
#       add call to ${PG_DBUTILS}/bin/testRadarEntrezGene.csh
#       

cd `dirname $0` && source ./Configuration

setenv LOG      ${EGLOGSDIR}/`basename $0`.log
rm -rf ${LOG}
touch ${LOG}

date | tee -a ${LOG}

echo 'Sanity check the radar.dp_entrezgene tables' | tee -a ${LOG}
${PG_DBUTILS}/bin/testRadarEntrezGene.csh | tee -a ${LOG}
if ( $status != 0 ) then
        echo 'radar.dp_entrezgene tables did not pass sanity check; skipping entrezgeneload' | tee -a ${LOG}
        exit 0
endif
echo 'radar.dp_entrezgene tables passed sanity check; continuing with entrezgeneload' | tee -a ${LOG}

${ENTREZGENELOAD}/updateIDs.csh | tee -a ${LOG}
${ENTREZGENELOAD}/human/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/rat/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/dog/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/chimpanzee/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/cattle/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/chicken/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/zebrafish/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/monkey/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/xenopus/load.csh | tee -a ${LOG}
${ENTREZGENELOAD}/xenopuslaevis/load.csh | tee -a ${LOG}

date | tee -a ${LOG}
