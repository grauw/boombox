ext debugdevice
set debugoutput stdout
debug set_watchpoint read_io 0x2E

diskmanipulator create /tmp/soundstar.dsk 32M
hda /tmp/soundstar.dsk
diskmanipulator import hda bin/

set maxframeskip 100
set throttle off
after time 5 "set throttle on"
