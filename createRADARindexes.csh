#!/bin/csh -f

#
# Create RADAR indexes
#
# Usage:  createRADARindexes.csh
#
# History
#

# create indexes
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Nomen_create.object
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Mapping_create.object
${PG_RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Synonym_create.object

