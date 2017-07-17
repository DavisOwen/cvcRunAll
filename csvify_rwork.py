#!/usr/bin/env python

#<usage> csvify_rwork.py <refmac refined pdb file>

import sys

f = open(sys.argv[1],'r')
g = open('rwork.csv','w+')
for line in f:
	string = line.split()
	if len(string) > 5:
		if string[0] == 'REMARK' and string[2] == 'R' and string[3] == 'VALUE' and string[4] == '(WORKING' and string[5] == 'SET)':
			g.write(string[-1]+',')
		if string[0] == 'REMARK' and string[2] == 'FREE' and string[3] == 'R' and string[4] == 'VALUE' and string[5] == ':':
			g.write(string[-1]+',')