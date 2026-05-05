import sys 
import os
import db

inFolder = os.environ['EGINPUTDIR'] + '/'
fileName = sys.argv[1]
outFile = open(inFolder + fileName + '.mgi', 'w')
print(inFolder + fileName)
with open(inFolder + fileName, 'r') as f:
    for line in f:
        tokens = line[:-1].split('\t')
        taxid = tokens[0]
        if taxid in ('10090', '9606', '10116', '9615', '9598', '9913', '9031', '7955', '9544', '8364', '8355'):
            outFile.write(line)

outFile.close()

