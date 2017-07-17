#!/usr/bin/env python

import sys
import os

#usage: csvify_MP.py <molprobity results file> <pdb name>

f = open(sys.argv[1],'r')
new_str = str()
found = False
for line in f:
	string = line.split(':')
	if string[0] == '' and string[1][1:-1] == sys.argv[2] and found == False:
		new_str += string[1][1:-5]+','
		found = True
	elif found:
		if string[0] == 'clashscore':
		   new_str += string[1][1:-1]+','
		if string[0] == 'rota<1%':
		   new_str += string[1][1:-1]+','
		if string[0] == 'ramaOutlier':
		   new_str += string[1][1:-1]+','
		if string[0] == 'MolProbityScore':
			new_str += string[1][1:-1]+','
			break

g = open(sys.argv[2][:-4]+'MP.csv','w+')
os.remove(sys.argv[1])
g.write(new_str)	
