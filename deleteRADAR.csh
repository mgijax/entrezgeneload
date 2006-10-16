#!/bin/csh -fx

#
# Delete record from RADAR for given Taxonomic ID
#
# Usage:  deleteRADAR.csh
#
# History
#

cat - <<EOSQL | doisql.csh ${RADAR_DBSERVER} ${RADAR_DBNAME} $0
 
use ${RADAR_DBNAME}
go

delete from WRK_EntrezGene_Bucket0 where taxID = ${TAXID}
go

delete from WRK_EntrezGene_Nomen where taxID = ${TAXID}
go

delete from WRK_EntrezGene_Mapping where taxID = ${TAXID}
go

delete from WRK_EntrezGene_Synonym where taxID = ${TAXID}
go

EOSQL

# drop indexes
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Nomen_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Mapping_drop.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Synonym_drop.object

