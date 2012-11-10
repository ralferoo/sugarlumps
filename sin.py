#!/usr/bin/python

import math

if False:
   print "base_sin_table:"
   for x in xrange(0,256):
	a = x * 3.1415 * 2 / 256;
	s = math.sin(a)
	#r = 128+int(s*83)
	r = int(s*127)
#	if r<0: r = r+256
	print "\tdefb %5d\t\t; sin(%3d)"%(r,x)

if False:
   print "offset_sin_table:"
   for x in xrange(0,256):
	a = x * 3.1415 * 2 / 256;
	s = math.sin(a)
	r = int(s*43)
	print "\tdefb %5d\t\t; sin(%3d)"%(r,x)

if True:
   print "quadrant_of_sin_table:"
   for x in xrange(0,65):
	a = x * 3.1415 * 2 / 256;
	s = math.sin(a)
	#r = 128+int(s*128)
	r = 128+int(s*128)
	print "\tdefb %5d\t\t; sin(%3d)"%(r,x)


