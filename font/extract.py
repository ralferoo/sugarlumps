#!/usr/bin/python

import PIL
import Image
import ImageFont
import ImageDraw

font = ImageFont.truetype("04B_30__.TTF", 16*8)

class stream:
	def __init__(self):
		self.bsent = []
		self.bpending = []
		self.ctrl = 0
		self.ctrl_bits = 0
		self.curr_char = -1
		self.table = [	0x3ffc, 0x3ffc, 0x3ffc, 0x3ffc,
				0x7fbe, 0x7bbe, 0x7ffc, 0x739e,
				0x701e, 0x1ff8, 0x003e, 0x7bfe,
				0x7800, 0x3ffe, 0x001e, 0x7fe0 ];
		self.raw = ""
		self.test = ""
	
	def pushbit(self,b):
		self.ctrl = self.ctrl*2
		if b <> 0: self.ctrl = self.ctrl + 1
		self.ctrl_bits = self.ctrl_bits + 1
		if self.ctrl_bits == 8:
			self.ctrl_bits = 0
			self.bsent.append(self.ctrl)
			self.ctrl = 0
			self.bsent = self.bsent + self.bpending
			self.bpending = []
		self.emit()
	
	def pushbyte(self,b):
		if self.ctrl_bits == 0:
			self.bsent.append(b)
		else:	self.bpending.append(b)
		self.emit()
	
	def end(self):
		self.test = self.test + chr(0)
		print"flushing"
		self.pushbit(1)		# next char
		self.pushbyte(0)	# char 0
		while self.ctrl_bits > 0:
			self.pushbit(1)
		self.emit()
#		r = self.bsent
#		self.bsent = []
#		return r
	
	def startchar(self,c,w,hp):
		if len(hp)>0:	h=hp[0]
		else:		h=(15,15)
		self.test = self.test + chr(c) + chr(w) + chr(h[0])+chr(h[1])
		print "startchar #%02x width %d highlight at %s"%(c,w,h)
		if self.curr_char + 1 == c:
			self.pushbit(0)
		else:
			self.pushbit(1)
			self.pushbyte(c)
		self.curr_char = c
		
		if w==14:
			self.pushbit(0)
		else:
			self.pushbit(1)
			for i in xrange(0,4):
				self.pushbit( w&8 )
				w = w * 2
		
		if h[0] == 1:
			self.pushbit(0)
		else:
			self.pushbit(1)
			if h[0] == 3:
				self.pushbit(0)
			elif h[0] == 8:
				self.pushbit(1)
			else:
				self.pushbit(1)
				print "ERROR - highlight x not 1,3 or 8"
		
		if h[1] == 2:
			self.pushbit(0)				# 2 -> 0
		else:
			self.pushbit(1)
			if h[1] == 3:
				self.pushbit(0)			# 3 -> 10
			elif h[1] == 10:
				self.pushbit(1)			# 10 -> 110
				self.pushbit(0)
			elif h[1] == 11:
				self.pushbit(1)			# 11 -> 111
				self.pushbit(1)
			else:
				self.pushbit(1)
				print "ERROR - highlight y not 2,3,10 or 11"
	
	def emit(self):
		for b in self.bsent:
			print "defb #%02x"%(b)
			self.raw = self.raw + chr(b)
		self.bsent = []
	
	def emitcode(self,v):
		self.test = self.test + chr(v>>8) + chr(v&0xff)
		if v == 0x7ffe:
			print "code #%04x -> 1"%(v)
			self.pushbit(1)
			return

		self.pushbit(0)

		for i in xrange(0,len(self.table)):
			if self.table[i] == v:
				print "code #%04x -> 00+tbl %d"%(v,i)
				self.pushbit(0)
				self.pushbit( i&8 )
				self.pushbit( i&4 )
				if (i&12)==0: return
				self.pushbit( i&2 )
				self.pushbit( i&1 )
				return

		print "code #%04x -> 01+lit"%(v)
		self.pushbit(1)
		self.pushbyte(v >> 8)
		self.pushbyte(v & 0xff)

# 7ffe	1
# lit   0 1
# 3ffc	0 000
# table 0 0xxxx

out = stream()

def encode(p):
	v = 0
	for i in xrange(0,len(p)):
		c = p[i]
		v = v * 2
		if c<>' ' and c<>'.':
			v = v +1

	out.emitcode(v)

y_lines = []
def addy(y):
	for i in y_lines:
		if i==y: return
	y_lines.append(y)

x_cols = []
def addx(x):
	for i in x_cols:
		if i==x: return
	x_cols.append(x)

def cpcify(lines, c):
	data = "" + c +chr(len(lines[0])) #+chr(len(lines)-0)
	for x in xrange(0,len(lines[0]),4):
		for l in lines[0:]:
			b = 0
			for p in xrange(0,4):
				i = x+p
				if i < len(l):
					if l[i]=='#':	col = 0xf0
					elif l[i]=='o':	col = 0x0f
					elif l[i]=='+':	col = 0xff
					else:		col = 0x00
				else: col = 0
				if p==0:	mask = 0x88
				elif p==1:	mask = 0x44
				elif p==2:	mask = 0x22
				elif p==3:	mask = 0x11
				b = b + (col&mask)
			data = data + chr(b)
			b = 0
	return data

def choose_points(l):
	r=[]
	f=l[0]
	for i in l:
		if i<=1+f:
			f = i
		else:
			#r.append( (f,i-1) )
			r.append( int((f+i-1)/2) )
			f = i
	return r

valid_x = []
valid_y = []

def bl(c):
	if c=="." or c==" ": return False
	return True

def rotate(b):
	r = []
	for x in xrange(0,len(b[0])):
		rr = ""
		for y in xrange(0,len(b)):
			rr = rr+ b[y][x]
		r.append(rr)
	return r

def pretty(lines,ch):
	b = []
	h = []
	for l in lines:
		bb = [ ]
		hh = [ ]
		for x in xrange(0,len(l)):
			c=l[x]
			bb.append( c<>"." and c<>" " )
			hh.append( False )
		b.append(bb)
		h.append(hh)

	if ch==" ":	hplist = []
	elif ch=='"':	hplist = [ (1,3), (2,3), (1,4), (8,3), (9,3), (8,4)  ]
	elif ch=="$":	hplist = []
	elif ch=="&":	hplist = []
	elif ch=="@":	hplist = []
	elif ch=="'":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch=="(":	hplist = [ (3,2), (4,2), (3,3) ]
	elif ch=='#':	hplist = [ (3,2), (4,2), (3,3) ]
	elif ch=='+':	hplist = [ (5,2), (6,2), (5,3) ]
	elif ch==',':	hplist = [ (1,10), (2,10), (1,11) ]
	elif ch=='.':	hplist = [ (1,10), (2,10), (1,11) ]
	elif ch=='-':	hplist = [ (1,7), (2,7), (1,8) ]
	elif ch=="/":	hplist = []
	elif ch==":":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch==";":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch=="<":	hplist = [ (4,2), (5,2), (4,3) ]
	elif ch=="=":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch=="J":	hplist = [ (8,2), (9,2), (8,3) ]
	elif ch=="^":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch=="_":	hplist = [ (1,11), (2,11), (1,12) ]
	elif ch=="`":	hplist = [ (1,3), (2,3), (1,4) ]
	elif ch=="j":	hplist = [ (7,4), (8,4), (7,5) ]
	elif ch>="a" and ch<='z':
			hplist = [ (1,4), (2,4), (1,5) ]
	elif ch=="{":	hplist = []
	elif ch=="~":	hplist = [ (1,3), (2,3), (1,4) ]
	else:		hplist = [ (1,2), (2,2), (1,3) ]
	dohp = True
	for hp in hplist:
		if b[hp[1]][hp[0]] == True: dohp = False
	if dohp:
		for hp in hplist:
			h[hp[1]][hp[0]] = True
			b[hp[1]][hp[0]] = True
	else:
		print "NO HP FOUND FOR %c"%(ch)

	m = []
	for y in xrange(0,len(b)):
		mm = []
		for x in xrange(0,len(b[0])):
			if x==0 or y==0 or x==len(b[0])-1 or y==len(b)-1:
				mask = False
			else:
				mask = True
#				mask = mask and b[y-1][x-1]
				mask = mask and b[y][x-1]
#				mask = mask and b[y+1][x-1]

				mask = mask and b[y-1][x]
				mask = mask and b[y+1][x]

#				mask = mask and b[y-1][x+1]
				mask = mask and b[y][x+1]
#				mask = mask and b[y+1][x+1]

			mm.append(mask)
		m.append(mm)

	l2 = []
	for y in xrange(0,len(b)):
		l = ""
		for x in xrange(0,len(b[0])):
			bbb = b[y][x]
			mmm = m[y][x]
			hhh = h[y][x]
			if hhh: l=l+"#"
#			elif bbb and mmm: l=l+"+"
#			elif bbb: l=l+"o"
			elif bbb and not mmm: l=l+"o"
			elif bbb: l=l+"+"
			else:	l=l+" "
		l2.append(l)
	return (l2,hplist)

def extract(c):
	sz=font.getsize(c)
	im = Image.new("RGB", sz, (0,0,0))
	ImageDraw.Draw(im).text( (0,0), c, font=font, fill=(255,255,255))
	plast = ""
	for y in xrange(0,sz[1],1):
#	for y in [4, 12, 20, 28, 36, 44, 52, 59
		ignore = False
		p=""
		for x in xrange(0,sz[0],1):
			px = im.getpixel((x,y))
			if (x % 1000)==0 : p = p + ","
			elif px[0] == 255:
				p = p + "#"
#			elif px[0] == 0:
#				p = p + "."
			else:
				p = p + " " #chr(48+px[0]/32) #"."
#				ignore = True
		if (not ignore) and (p <> plast):
#			print "%3d |%s|"%(y,p)
			plast = p
			addy(y)
			for i in xrange(1,len(p)):
				if p[i-1] <> p[i]:
					addx(i)
			addx(len(p))
#	addy(sz[1])
	
	lines=[]
	for y in valid_y:
		if y >= sz[1]: break
		p = ""
		for x in valid_x:
			if x >= sz[0]: break
			px = im.getpixel((x,y))
			if px[0] == 255:
				p = p + "#"
			else:
				p = p + " "
		lines.append(p)
	return lines

misc=" !\"',.?;:()_/%+-"
chars=list(xrange(48,58)) + list(xrange(ord('A'),ord('Z')+1)) # + list(xrange(ord('a'),ord('z')+1))
for i in xrange(0,len(misc)): chars.append(ord(misc[i]))

#chars=list(xrange(ord('A'),ord('Z')+1))

#chars=list(xrange(32,127))

#for i in "0123456789".items()
#	extract(chr(i))
#for i in chars:
#for i in xrange(32, 127): #ord('A'),ord('D')+1):
#for i in xrange(ord('A'),ord('Z')+1):
#	extract(chr(i))

#x_cols.sort()
#y_lines.sort()

#valid_x = choose_points(x_cols)
#valid_y = choose_points(y_lines)

valid_x = [4, 12, 20, 26, 34, 41, 49, 57, 64, 72, 79, 87, 94, 101, 109, 116, 123]
valid_y = [3, 11, 18, 26, 33, 41, 48, 56, 63, 70, 78, 85, 93, 101, 108, 116]

#chars=[ ord(".") ]

#print valid_x
#print valid_y

f = open("dnd_font.raw", "wb")

for i in chars:
#for i in xrange(32, 127): #ord('A'),ord('D')+1):
#for i in xrange(ord('A'),ord('Z')+1):
	c=chr(i)
	lines=extract(c)

#	print "%c: %d x %d"%(c, len(lines[0]), len(lines))

	for y in xrange(0,len(lines)):
		if lines[y][-2:] <> "  ":
			print "ERROR:",lines[y]
		else:
			lines[y] = lines[y][:-2]

#	print "%c: %d x %d"%(c, len(lines[0]), len(lines))
	if c=='A':
		lines=lines[:7]+lines[6:9]+lines[10:]
	elif c=='0':
		for j in [5,6,7]:
			lines[j  ] = lines[j  ][:9]+'#'+lines[j  ][10:]
			lines[j+1] = lines[j+1][:8]+'#'+lines[j+1][ 9:]
			lines[j+2] = lines[j+2][:7]+'#'+lines[j+2][ 8:]
	elif c=='1':
		for j in xrange(0,5):
			lines[j  ] = lines[j][:6]+lines[j][5:]
		for j in xrange(5,len(lines)):
			lines[j  ] = lines[j][:2]+lines[j][1:]
	elif c=='I' or c=='M' or c=='W':
		for j in xrange(0,len(lines)):
			lines[j  ] = lines[j][:4]+lines[j][5:]
	elif c=='L':
		for j in xrange(0,len(lines)):
			lines[j  ] = lines[j][:9]+lines[j][8:]
	elif c=='-':
		for j in xrange(0,len(lines)):
			lines[j  ] = lines[j][:9]+lines[j][7:]

	for i in lines:
		print i

	(lines,hp) = pretty(lines,c)

	if c=='.':
		lines=lines[0:1]+lines[:-1]

	if c=='"' or c=="'" or c==";": # or c==":":
		#print "Removing top 1"
		lines=lines[1:]+lines[-1:]

	if c<>'"' and c<>' ' and c<>'(' and c<>')':
		for j in xrange(0,len(lines)):
			lines[j] = " "+lines[j]+" "

	print "%c: %d x %d"%(c, len(lines[0]), len(lines))
	if (len(lines[0])%4)<>0:
		print "WARNING, non byte width"

	for p in lines:
		print p

	f.write(cpcify(lines, c))

	print "--------------------------------"

#	out.startchar(i, len(lines[0]), hp)
#	rotlines = rotate(lines)
#	for p in rotlines:
#		encode(p)

#out.end()
f.write(chr(0))
f.close()

#f = open("compressed_font.bin", "wb")
#f.write(out.raw)
#f.close()

#f = open("raw_font.bin", "wb")
#f.write(out.test)
#f.close()

