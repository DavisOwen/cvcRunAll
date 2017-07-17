#!/usr/bin/env python

import os
import sys

def newchains(pdb,chains):
	for chain in chains:
		f = open(pdb,'r')
		outfile = open(sys.argv[2]+pdb[-8:-4]+chain+'.pdb','w+')
		for line in f:
			string = line.split()
			if (string[0] == 'ATOM' or string[0] == 'ANISOU') and line[21] != chain:
				pass
			elif string[0] == 'TER' and line[21] != chain:
				pass
			else:
				outfile.write(line)
		f.close()

chains = list()
f = open(sys.argv[1],'r')
for line in f:
	string = line.split()
	if string[0] == 'ATOM' or string[0] == 'ANISOU':
		if line[21] not in chains:
			chains.append(line[21])
f.close()
newchains(sys.argv[1],chains)
