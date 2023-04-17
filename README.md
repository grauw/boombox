SoundStar Boombox firmware ROM
==============================

Copyright 2023 Laurens Holst

Music copyright by David Sanders
Hardware by SuperSoniqs


Project information
-------------------

SoundStar Boombox firmware ROM.

  * Author: Laurens Holst <laurens@grauw.nl>
  * Site: <https://shop.supersoniqs.com/en/home/106-soundstar.html>
  * Source: <https://hg.sr.ht/~grauw/soundstar>
  * License: Simplified BSD License (code, art), No License (music)

The firmware serves three purposes; to allow for detection of the SoundStar,
to initialise the SAA1099 sound chip after a reset, and to give a demonstration
of SoundStar’s capabilities. The Boombox music demo lets you listen to some
great tracks created by David Sanders (Pyramex), one of the sound stars of the
British Sam Coupé scene.


System requirements
-------------------

  * MSX
  * 32K main RAM
  * 16K video RAM
  * SuperSoniqs SoundStar


Usage
-----

On boot the firmware ROM resets the Philips SAA1099 sound chip, to silence it in
case the computer is reset while it was playing, since the chip has no reset
input pin of its own.

Software can detect the presence of SoundStar by checking for the `SAA1099` ID
string at address `4010H` in one of the slots. When found, the SoundStar can be
accessed on I/O ports `04H` (data) and `05H` (address). Refer to the [SAA1099
application manual][1] for technical information and the register description.

To run the Boombox player, either keep RETURN or joystick 1 button A pressed
while booting the computer or call `_SOUNDSTAR` from MSX-BASIC.

In the Boombox player, you can use the following controls:

  * Cursors or d-pad to select track / side
  * SPACE or A to play / pause track
  * BACKSPACE or B to stop track
  * CAPS LOCK to enable autoplay
  * SELECT to toggle frequency
  * ESC to quit

[1]: https://map.grauw.nl/resources/sound/philips_saa1099.pdf
     "SAA1099 application manual"


Development information
-----------------------

The SoundStar Boombox ROM is free and open source software, with the exclusion
of the music. If you want to contribute to the project you are very welcome to.
Please contact me at any one of the places mentioned in the project information
section.

You are also free to re-use code for your own projects, provided you abide by
the license terms.

Clone the project with Mercurial:

    hg clone https://hg.sr.ht/~grauw/tiletile

Building the project is easy on all modern desktop platforms. On MacOS and
Linux, simply invoke `make` to build the binary and symbol files into the `bin`
directory:

    make

Windows users can open the `Makefile` and build by pasting the lines in the
`all` target into the Windows command prompt.

To launch the build in openMSX after building, invoke the `make run` command.

Note that the [glass](http://www.grauw.nl/projects/glass/) assembler which is
embedded in the project requires [Java 8](http://java.com/getjava). To check
your Java version, invoke the `java -version` command.

Additionally, the build tools are written in JavaScript for Node.js. You need to
have Node.js and NPM installed.
