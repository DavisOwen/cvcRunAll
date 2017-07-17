#!/usr/bin/env python

#usage getAmberEnergies.py <pdb file name>

import sys

f = open('./AMBER/'+sys.argv[1]+'.amberout','r')
g = open('amber.csv','w+')

nextline = False
nextlines = False
c=int()

for line in f:
	string = line.split()
	if len(string) > 0:
		if string[0] == 'NSTEP':
			nextline = True
			if nextlines == True:
				break
		elif nextline:	
			if string[0] == '1':
				total = string[1]
				nextlines = True
			nextline = False
		elif nextlines:
			if len(string) > 0:
				if c < 2:
					g.write(string[2]+','+string[5]+','+string[8]+',')
					c += 1
				else:
					g.write(string[3]+','+string[7]+','+string[10]+',')
g.write(total+',')
