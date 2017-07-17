#!/usr/bin/env python

import sys
import os

#usage csvify_energy.py <pdb file> <pdb name>

f = open(sys.argv[1],'r')
newstr = str()
line = f.readline()
string = line.split()
for item in string:
	newstr += item+','
os.remove(sys.argv[1])
g = open(sys.argv[1][:-4]+'.csv','w+')
g.write(newstr)
