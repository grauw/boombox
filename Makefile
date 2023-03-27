COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p gen bin
	java -jar tools/glass.jar src/SoundStarROM.asm bin/soundstar.rom gen/soundstar.sym
	java -jar tools/glass.jar src/BoomboxROM.asm bin/boombox.rom gen/boombox.sym
	java -jar tools/glass.jar src/BoomboxCOM.asm bin/boombox.com
	java -jar tools/glass.jar src/ETCPlayerSAA.asm bin/etcplayer.saa

dist: all
	cp README.md bin/
	rm -f bin/soundstar.zip
	cd bin && zip soundstar.zip soundstar.rom README.md

copy: all
	cp bin/*.rom $(COPY_TARGET)/
	cp bin/*.com $(COPY_TARGET)/
	diskutil umount $(COPY_TARGET)

run: all
	openmsx -machine Panasonic_FS-A1GT -ext slotexpander -ext SoundStar -cart bin/boombox.rom -ext ide -script openmsx.tcl
