#!/usr/bin/env python

import os
import sys

inVal = open(sys.argv[1],'r+')
outVal = open('a','w+')
for line in inVal:
	string = line.split()
	try:
		if string[0] == 'Warning:':
			pass
		else:
			outVal.write(line)	
	except IndexError:
		pass

next = False
os.remove(sys.argv[1])
newVal = open(sys.argv[1],'w+')
outVal.seek(0)
for line in outVal:
	if line[:12] == '#pdbFileName':
		table = line[12:]
		table = table.split(':')
		next = True
	elif next:
		new = line.split(':')
		for i in range(len(new)):
			newVal.write(table[i]+': '+new[i]+'\n')

os.remove('a')
