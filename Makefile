COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p gen bin
	node tools/generate.js res/resources.json
	java -jar tools/glass.jar -I gen src/SoundStarROM.asm bin/soundstar.rom gen/soundstar.sym
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
	openmsx -machine Panasonic_FS-A1GT -ext slotexpander -ext SoundStar -cart bin/soundstar.rom -ext ide -script openmsx.tcl

run2: all
	openmsx -machine Philips_VG_8020 -ext slotexpander -ext SoundStar -cart bin/soundstar.rom -ext ide -script openmsx.tcl

run3: all
	openmsx -machine Yamaha_CX5M -ext slotexpander -ext SoundStar -cart bin/soundstar.rom -ext ide -script openmsx.tcl

run4: all
	openmsx -machine Sony_HB-75 -ext slotexpander -ext SoundStar -cart bin/soundstar.rom -ext ide -script openmsx.tcl

run5: all
	openmsx -machine Sony_HB-10 -ext slotexpander -ext SoundStar -cart bin/soundstar.rom -ext ide -ext ram16k -script openmsx.tcl
