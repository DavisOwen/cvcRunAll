#!/usr/bin/env python

#usage <pdb files to combine> <name of pdb>

import os
import sys

g = open(sys.argv[-1]+'.pdb','w+')
f = open(sys.argv[1],'r')
begstr = str()
endstr = str()
new = False
for line in f:
	string = line.split()
	if string[0] == 'ATOM' or string[0] == 'ANISOU' or string[0] == 'TER':
		new = True
	elif new:
		endstr += line
	else:
		begstr += line

g.write(begstr)

second = False
num = int()
for arg in sys.argv[2:-1]:
	f = open(arg,'r')
	for line in f:
		if second:
			string = line.split()
			newnum = num + int(string[1])
			line = line[:11-len(str(newnum))]+str(newnum)+line[11:77]+string[2][0]+'\n'
			g.write(line)
		else:
			string = line.split()
			line = line[:77]+string[2][0]+'\n'
			g.write(line)
	f.seek(0)
	linelist = f.readlines()
	lastline = linelist[-1].split()
	num = int(lastline[1])+num+1
	res = lastline[3]
	chain = lastline[4]
	lastline = 'TER    '+str(num)+'      '+str(res)+' '+str(chain)+'\n'
	g.write(lastline)
	second = True
	os.remove(arg)

g.write(endstr)
