#!/bin/csh -fx

#
# Create RADAR indexes
#
# Usage:  createRADARindexes.csh
#
# History
#

# create indexes
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Bucket0_create.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Nomen_create.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Mapping_create.object
${RADAR_DBSCHEMADIR}/index/WRK_EntrezGene_Synonym_create.object

