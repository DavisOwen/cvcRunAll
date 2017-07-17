#!/usr/bin/env python

import sys
f = open(sys.argv[1],'r')
for line in f:
	string = line.split()
	if len(string) >1 and string[0] == 'Requested' and string[1] == 'size':
		print(string[4][:-1])
