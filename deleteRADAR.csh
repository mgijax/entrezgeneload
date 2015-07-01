#!/bin/csh -f

#
# Delete record from RADAR for given Taxonomic ID
#
# Usage:  deleteRADAR.csh
#
# History
#

cat - <<EOSQL | ${PG_DBUTILS}/bin/doisql.csh $0 >>& ${LOG}
 
delete from WRK_EntrezGene_Bucket0 where taxID = ${TAXID}
;

delete from WRK_EntrezGene_Nomen where taxID = ${TAXID}
;

delete from WRK_EntrezGene_Mapping where taxID = ${TAXID}
;

delete from WRK_EntrezGene_Synonym where taxID = ${TAXID}
;

EOSQL

# drop indexes
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Nomen_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Mapping_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Synonym_drop.object

