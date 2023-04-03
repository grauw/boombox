;
; SoundStar ROM
;
SoundStar_BASE_PORT: equ 04H
SoundStar_ADDRESS: equ SoundStar_BASE_PORT + 1
SoundStar_DATA: equ SoundStar_BASE_PORT + 0

	org 4000H

page1:
	ds 4000H, 0
page2:
	ds 4000H, 0
	ds 4000H, 0
	ds 4000H, 0

	SECTION page1

	db "AB"
	dw ROM_Main
	dw 0, 0, 0, 0, 0, 0

	db "SAA1099", 0  ; ID
	dw 0001H         ; Version
	db "SuperSoniqs SoundStar", 0

ROM_Main:
	ei
	ld hl,RAM_source
	ld de,RAM_destination
	ld bc,RAM_size
	ldir
	call Reset
	ld ix,ROM_boombox
	call Boombox_Construct
	call Boombox_Run
	call Boombox_Destruct
	jp Reset

Reset: PROC
	ld a,1CH
	out (SoundStar_ADDRESS),a
	ld a,02H
	out (SoundStar_DATA),a
	ld b,20H
Loop:
	ld a,20H
	sub b
	out (SoundStar_ADDRESS),a
	xor a
	out (SoundStar_DATA),a
	djnz Loop
	ret
	ENDP

	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "Boombox.asm"

Module1_data:
	; INCBIN "../res/Pyramex - Electro-1 (2012).cop", 04B3H
	; INCBIN "../res/Pyramex - Electro-2 (2022).saa", 04B3H
	; INCBIN "../res/Pyramex - Electro-3 (2022).saa", 04B3H
	; INCBIN "../res/Pyramex - Electron (2018).etc", 04B3H
	; INCBIN "../res/Pyramex - High Color (2018) (speccy.pl party 2018.1, 1).cop", 04B3H
	; INCBIN "../res/Pyramex - Seventh (2018).cop", 04B3H
	INCBIN "../res/Pyramex - Vexx Ingame (2005).etc"

	SECTION RAM

ROM_boombox:
	Boombox

ETCPlayer_BUGFIX: equ 1
ETCPlayer_SAA_ADDRESS_PORT: equ SoundStar_ADDRESS
ETCPlayer_SAA_MODE_REG: equ c

	INCLUDE "ETCPlayer.asm"

	ENDS

RAM_source:
	org 0C000H
RAM_destination:
RAM: ds 500H
RAM_size: equ $ - RAM_destination
	org RAM_source + RAM_size

	ENDS
