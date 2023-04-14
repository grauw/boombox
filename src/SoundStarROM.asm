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
	dw Main
	dw 0, 0, 0, 0, 0, 0

	db "SAA1099", 0  ; ID
	dw 0001H         ; Version
	db "SuperSoniqs SoundStar", 0

Main:
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

	ENDS
