'''
#
# Purpose:
#
#	Create bcp records for ACC taxIds for EntrezGene load.
#  
# Input:
#
#	None
#
# Assumes:
#
#	radar.WRK_EntrezGene_Bucket0 exists
#
# Output:
#
#	BCP files:
#
#	ACC_Accession.bcp		Accession records
#	ACC_AccessionReference.bcp	Accession/Reference records
#	MRK_Marker.bcp			new Marker records
#
# Processing:
#
# History:
#
# lec	02/21/2001
#	- created
#
'''

import sys
import os
import db
import accessionlib
import mgi_utils
import loadlib

#globals

taxId = os.environ['TAXID']
datadir = os.environ['DATADIR']
referenceKey = os.environ['REFERENCEKEY']	# _Refs_key of Reference
mgiTypeKey = os.environ['MARKERTYPEKEY']	# _Marker_Type_key of a Marker
egKey = os.environ['LOGICALEGKEY']		# _LogicalDB_key of EntrezGene
organism = os.environ['ORGANISM']
user = os.environ['CREATEDBY']

accFileName = datadir +  '/ACC_Accession.bcp'
accrefFileName = datadir +  '/ACC_AccessionReference.bcp'
markerFileName = datadir + '/MRK_Marker.bcp'
diagFileName = datadir + '/accids.diagnostics'

accFile = None
accrefFile = None
markerFile = None
diagFile = None

accKey = 0	# primary key for Accession Numbers
markerKey = 0   # primary key for Markers
userKey = 0	# primary key for DB User

markerStatusKey = 1
markerTypeKey = 1

geneIDtoMarkerKey = {}

loaddate = loadlib.loaddate 	# Creation/Modification date for all records

def exit(status, message = None):
        '''
        # requires: status, the numeric exit status (integer)
        #           message (string)
        #
        # effects:
        # Print message to stderr and exits
        #
        # returns:
        #
        '''
 
        if message is not None:
                sys.stderr.write('\n' + str(message) + '\n')
 
        try:
                diagFile.write('\n\nEnd Date/Time: %s\n' % (mgi_utils.date()))
                diagFile.close()
                accFile.close()
                accrefFile.close()
                markerFile.close()
        except:
                pass

        sys.exit(status)
 
def init():
        '''
        # requires: 
        #
        # effects: 
        # 1. Processes command line options
        # 2. Initializes local DBMS parameters
        # 3. Initializes global file descriptors
        #
        # returns:
        #
        '''
 
        global accFile, accrefFile, markerFile, diagFile
        global accKey, userKey, markerKey
 
        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
        try:
                accFile = open(accFileName, 'w')
        except:
                exit(1, 'Could not open file %s\n' % accFileName)
                
        try:
                accrefFile = open(accrefFileName, 'w')
        except:
                exit(1, 'Could not open file %s\n' % accrefFileName)
                
        try:
                markerFile = open(markerFileName, 'w')
        except:
                exit(1, 'Could not open file %s\n' % markerFileName)

        #
        # Get next available primary key
        #

        results = db.sql('select max(_Accession_key) + 1 as maxKey from ACC_Accession', 'auto')
        accKey = results[0]['maxKey']

        results = db.sql(''' select nextval('mrk_marker_seq') as maxKey ''', 'auto')
        markerKey = results[0]['maxKey']

        userKey = loadlib.verifyUser(user, 0, None)

def writeAccBCP():
        '''
        # requires:
        #
        # effects:
        #	Creates approrpriate BCP records
        #
        # returns:
        #	nothing
        #
        '''

        global accKey, userKey

        # records that require a reference

        results = db.sql('select _Object_key, _LogicalDB_key, accID, private, geneID ' + \
                'from WRK_EntrezGene_Bucket0 ' + \
                'where taxID = %s and refRequired = 1 ' % (taxId), 'auto')

        for r in results:

                if r['_Object_key'] == -1:
                    objectKey = geneIDtoMarkerKey[r['geneID']]
                else:
                    objectKey = r['_Object_key']

                prefixPart, numericPart = accessionlib.split_accnum(r['accID'])
                accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
                        % (accKey, r['accID'], mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], objectKey, mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
                accrefFile.write('%d|%s|%s|%s|%s|%s\n' % (accKey, referenceKey, userKey, userKey, loaddate, loaddate))
                accKey = accKey + 1

        # records that don't require a reference

        results = db.sql('select _Object_key, _LogicalDB_key, accID, private, geneID ' + \
                'from WRK_EntrezGene_Bucket0 ' + \
                'where taxID = %s and refRequired = 0' % (taxId), 'auto')

        for r in results:

                if r['_Object_key'] == -1:
                    objectKey = geneIDtoMarkerKey[r['geneID']]
                else:
                    objectKey = r['_Object_key']

                accid = r['accID'].replace('Xenbase:', '')
                prefixPart, numericPart = accessionlib.split_accnum(accid)
                accFile.write('%d|%s|%s|%s|%d|%d|%s|%d|1|%s|%s|%s|%s\n'
                        % (accKey, accid, mgi_utils.prvalue(prefixPart), mgi_utils.prvalue(numericPart), r['_LogicalDB_key'], objectKey, mgiTypeKey, r['private'], userKey, userKey, loaddate, loaddate))
                accKey = accKey + 1

def writeMarkerBCP():
        '''
        # requires:
        #
        # effects:
        #	Creates approrpriate BCP records
        #
        # returns:
        #	nothing
        #
        '''

        global markerKey, geneIDtoMarkerKey

        # new Marker records

        results = db.sql('select b.accID, b.private,  e.symbol, e.name, e.chromosome, e.mapPosition ' + \
                'from WRK_EntrezGene_Bucket0 b, DP_EntrezGene_Info e ' + \
                'where b.taxID = %s and b._Object_key = -1 and b._LogicalDB_key = %s and b.accID = e.geneID' % (taxId, egKey), 'auto')

        for r in results:

            if r['mapPosition'] == '-':
                mapPosition = ''
            else:
                mapPosition = r['mapPosition']

            markerFile.write('%d|%s|%d|%d|%s|%s|%s|%s||%d|%d|%s|%s\n'
                % (markerKey, organism, markerStatusKey, markerTypeKey, r['symbol'], r['name'], r['chromosome'], mapPosition, userKey, userKey, loaddate, loaddate))

            geneIDtoMarkerKey[r['accID']] = markerKey
            markerKey = markerKey + 1

def executeBCP():
    '''
    # requires:
    #
    # effects:
    #   BCPs the data into the database
    #
    # returns:
    #   nothing
    #
    '''

    accFile.close()
    accrefFile.close()
    markerFile.close()
    db.commit()

    bcpCommand = os.environ['PG_DBUTILS'] + '/bin/bcpin.csh'

    bcp1 = '%s %s %s %s %s %s "|" "\\n" mgd' % \
        (bcpCommand, db.get_sqlServer(), db.get_sqlDatabase(), 'MRK_Marker', datadir, 'MRK_Marker.bcp')

    bcp2 = '%s %s %s %s %s %s "|" "\\n" mgd' % \
        (bcpCommand, db.get_sqlServer(), db.get_sqlDatabase(), 'ACC_Accession', datadir, 'ACC_Accession.bcp')

    bcp3 = '%s %s %s %s %s %s "|" "\\n" mgd' % \
        (bcpCommand, db.get_sqlServer(), db.get_sqlDatabase(), 'ACC_AccessionReference', datadir, 'ACC_AccessionReference.bcp')

    diagFile.write('%s\n' % bcp1)
    diagFile.write('%s\n' % bcp2)
    diagFile.write('%s\n' % bcp3)

    os.system(bcp1)
    os.system(bcp2)
    os.system(bcp3)

    # update mrk_marker_seq auto-sequence
    db.sql(''' select setval('mrk_marker_seq', (select max(_Marker_key) from MRK_Marker)) ''', None)
    db.commit()

#
# Main
#

init()
writeMarkerBCP()
writeAccBCP()
executeBCP()
exit(0)
