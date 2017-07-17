#!/usr/bin/env python

import os
import sys
import subprocess
import shutil

f = open(sys.argv[2],'r')
length = len(sys.argv[1])
for line in f:
	string = line.split()
	if len(string) >= 5:
		if string[1] == 'SUMMARY' and string[2] == 'OF' and string[3] == 'JOB':
			direct = string[4]
	if len(string) >= 4:
		if string[0] == 'Starting' and string[1] == 'Model':
				pdb = string[3]
				pdb = pdb[length:length+5]
				Results = subprocess.check_output('ls '+direct+'/RESULT', shell = True)
				Results = Results.split()
				for i in range(len(Results)):
					os.rename(direct+'/RESULT/'+Results[i],sys.argv[1]+pdb+'.pdb')
				shutil.rmtree(direct)
		if string[0] == 'Job' and string[1] == 'ID':
			jobid = string[3]
		if string[0] == 'Refining' and string[1] == 'model...Exception':
			a = open(jobid+'/LOG/DSSP_1.txt','r')
			for foo in a:
				st = foo.split()
				if st[0] == 'HEADER':
					fail = st[-2]
					break
			b = open(jobid+'/LOG/LOG_1.txt','r')
			for foo in b:
				st = foo.split()
				if st[0] == 'assignRandomCaCoordinates':
					chain = st[2][-1]
					break
			os.rename(jobid,fail+chain+'_FAILED')
os.remove(sys.argv[2])
