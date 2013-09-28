all: sugarlumps.cdt sugarlumps.dsk sugarlumps.zip sugarlumps.rom

#all: patch.cdt
#linear.cdt linear.wav loader.cdt loader.wav unpacker.bin testdata.wav testdata.cdt

ASMS = $(wildcard *.asm)
COMPATS = $(patsubst %.asm,%.d,$(ASMS))

-include $(COMPATS)

x:
	@echo $(COMPATS)

play: linear.play

cpc: loader.wav
	aplay $<

linear: linear.wav
	aplay $<

emu:
	nice wine ../cpc/wincpc/WinCPC.exe &

clean:
	rm -f *.wav *.cdt *.bin *.au *.pak *.sym *.asm.out *.compat *.exe *.d *.dsk sugarlumps.zip
	( cd include ; rm -f *.wav *.cdt *.bin *.au *.pak *.sym *.asm.out *.compat *.exe *.d )

%.zip: %.dsk %.cdt %-slow.cdt %.rom %-slow.cdt %-readme.txt
	cp .git/refs/heads/master git-revision.txt
	zip $@ $*.dsk $*.cdt $*-slow.cdt $*.rom $*-readme.txt git-revision.txt
	rm -f  git-revision.txt

publish:
	git pull
	make clean
	make loader.cdt
	cp loader.cdt /var/www/virtual/ranulf.net/test.cdt
	chmod a+rx /var/www/virtual/ranulf.net/test.cdt

patch.exe: create_patches.pak unpacker0800.bin
	cat unpacker0800.bin create_patches.pak >$@

# sin.asm is read from build_sin_table.asm, so the normal rules break down
sugarlumps.bin: sin.compat date.bin

date.bin: Makefile $(ASMS)
	date '+%Y-%m-%d %H:%M' |tr 'a-z' 'A-Z' >$@

# iDSK comes from http://koaks.amstrad.free.fr/amstrad/projets/
%.dsk: %.exe %.bin Makefile
	[ -f $@ ] || iDSK $@ -n
	mkdir -p .idsk
	cp $*.exe .idsk/sugrlmps.bin
	iDSK $@ -i .idsk/sugrlmps.bin -e 8000 -c 8000 -t 1 -f
	rm .idsk/sugrlmps.bin
#	cp $*.bin .idsk/decomp.bin
#	iDSK $@ -i .idsk/decomp.bin -e 0800 -c 0800 -t 1
#	rm .idsk/decomp.bin
	rmdir .idsk

%.sna: %.sna.gz
	gunzip -c $< >$@

%.cdt: %.py Makefile
	./$< $@

%.exe: %.pak unpacker0800.bin
	cat unpacker0800.bin $< >$@

%.rom: %.pak unpacker0800rom.bin
	cat unpacker0800rom.bin $< >$@

%.pak: %.bin
	MegaLZ $< $@

plustest.exe: plustest.pak unpacker8000.bin
	cat unpacker8000.bin plustest.pak >$@

%.srec: %.exe
	objcopy --change-addresses=16384 -I binary $< -O srec $@
	
%-slow.cdt: %.exe Makefile
	2cdt -n -p 750 -b 1000 -X 32768 -L 32768 -r "`date '+%Y%m%d %H%M%S'`" $< $@

%.cdt: %.exe Makefile
	2cdt -n -p 750 -b 2600 -X 32768 -L 32768 -r "`date '+%Y%m%d %H%M%S'`" $< $@
#	2cdt -n -p 750 -b 1560 -X 32768 -L 32768 -r "`date '+%Y%m%d %H%M%S'`" $< $@

%.d: %.asm
	@echo Making $@
	@(perl -ne '{if (/read\s"([^"]*)\.asm\"/) {print "$*.bin: $$1.compat\n";}}' <$< | uniq ; echo $*.d: $*.asm ) >$@

%.compat: %.asm
	@echo Making $@
	@perl -pe '{s/readbin\s\"([^"]*)\"/incbin "$$1"/;s/read\s\"([^"]*)\.asm\"/include "$$1.compat"/;s/([xy][lh])/i$$1/g;s/(add\s+)(i)?([xy][lh])/$$1a,i$$3/g;s/(ex\s+)hl\s*,\s*de/$$1de,hl/g;s/ld\s+pc,(i[xy])/jp ($$1)/;s/rst\s+5/rst #28/g;s/;DATE;/incbin "date.bin"/;s/(add\s+)(\(i[xy])/$$1a,$$2/;}' <$< >$@

%.raw: %.bin
	dd bs=128 skip=1 if=$< of=$@

%.bin: %.compat
	pasmo $< $@ $*.sym

%.au: %.cdt
	playtzx -au -freq 44100 $< $@

%.wav: %.au
	sox $< $@

%.play: %.wav
	aplay $<

%.txt: %.bin
	hexdump -C $< >$@

sin.asm: sin.py
	./sin.py >sin.asm

testdata.cdt: file/Makefile file/addblock.c file/tzxfile.c file/tzxfile.h file/Makefile
	( cd file ; make )
	cp file/testdata.cdt .

testdata: testdata.wav
	aplay $<

#test.asm: sin.asm

nyan.inc: nyan.txt
	./rotate.py <$< |perl -pe '{s/^(.*)\n/\tdefb "$$1"\n/;}' >$@

include/bresenham_drawloop.asm: include/bresenham_drawloop_section.asm include/bresenham_drawloop.pl 
	@echo Building $@
	@include/bresenham_drawloop.pl <$< >$@

