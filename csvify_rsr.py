#!/usr/bin/env python

import sys
import os

#usage: csvify_rsr.py <rsr list file>

f = open(sys.argv[1],'r')
totrscc = float()
totrsr = float()
totn = int()

for line in f:
	if line[0] != '!':
		string = line.split()
		n = int(string[8])
		rscc = float(string[5])
		rsr = float(string[6])
		totrscc += rscc*n
		totrsr += rsr*n
		totn += n

totrscc = totrscc/totn
totrsr = totrsr/totn
g = open('rsr.csv','w+')
g.write(str(totrscc)+','+str(totrsr)+',')
