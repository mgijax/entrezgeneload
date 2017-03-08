#!/usr/local/bin/python

'''
#
# Purpose:
#
#	Create input record for Annotation load
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
#	${ANNOTATIONFILE}
#
# Processing:
#
# History:
#
# 03/01/2017	lec
# 	- TR12540/Disease Ontology (DO)
#
# 09/12/2013	lec
#	- TR11484/human/annotation.py/load.csh
#		a) load.csh : annotation.csh was turned OFF/turn back ON
#		b) mim-source "NULL" changed to "-"
#
# 04/28/2005	lec
#	- TR11195/OMIM/add check for annotation type ("phenotype")
#	and source (!= "NULL") to query
#
# 04/28/2005	lec
#	- TR 3853, OMIM
#
'''

import sys
import os
import string
import db
import mgi_utils
import loadlib

#globals

datadir = os.environ['DATADIR']
editor = os.environ['CREATEDBY']
reference = os.environ['DELETEREFERENCE']
logicalOMIM = os.environ['LOGICALOMIMKEY']
evidenceCode = 'TAS'
logicalDB = 'Entrez Gene'

omimToDOLookup = {}

annotFileName1 = os.environ['ANNOTINPUTFILE']
diagFileName = datadir + '/annotation.diagnostics'

annotFile = None
diagFile = None

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
		annotFile.close()
	except:
		pass

	db.useOneConnection(0)
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
 
	global annotFile1, diagFile
	global omimToDOLookup
 
        try:
            diagFile = open(diagFileName, 'w')
        except:
            exit(1, 'Could not open file %s\n' % diagFileName)
      
	try:
		annotFile1 = open(annotFileName1, 'w')
	except:
		exit(1, 'Could not open file %s\n' % annotFileName1)
		
	db.useOneConnection(1)

    	#   
    	# omimToDOLookup
    	# omim id -> do id
    	#   
    	results = db.sql('''
       		select distinct a1.accID as doID, a2.accID as omimID
       		from ACC_Accession a1, VOC_Term t, ACC_Accession a2
       		where t._Vocab_key = 125 
       		and t._Term_key = a1._Object_key
       		and a1._LogicalDB_key = 191 
       		and a1._Object_key = a2._Object_key
       		and a2._LogicalDB_key = 15
       		''', 'auto')
    	for r in results:
        	key = r['omimID']
        	value = r['doID']
        	omimToDOLookup[key] = []
        	omimToDOLookup[key].append(value)

def writeAnnotations1():
	'''
	# requires:
	#
	# effects:
	#	Creates approrpriate Annotation records
	#
	# returns:
	#	nothing
	#
	'''

	#
	# select OMIM disease annotations...
	# for those OMIM ids that are cross-referenced to DO...
	#	create annotation data
	#

	results = db.sql('''
		select distinct m.geneID, m.mimID as omimID
		from DP_EntrezGene_MIM m, ACC_Accession a
		where m.mimID = a.accID
		and a._MGIType_key = 13 
		and a._LogicalDB_key = %s
	        and (
		(m.annotationType = 'phenotype' and m.source != '-')
		or
		(m.annotationType = 'gene')
		)
		order by geneID
		''' % (logicalOMIM), 'auto')

	for r in results:

	    try:
	    	doid = omimToDOLookup[r['omimID']][0]
	        annotFile1.write('%s\t%s\t%s\t%s\t\t\t%s\t%s\t\t%s\n' \
			% (doid, r['geneID'], reference, evidenceCode, editor, loaddate, logicalDB))
	    except:
	    	diagFile.write('no DO match found for omim id : %s\n' % (r['omimID']))

#
# Main
#

init()
writeAnnotations1()
exit(0)

