;
; SoundStar ROM
;
SoundStar_BASE_PORT: equ 04H
SoundStar_ADDRESS: equ SoundStar_BASE_PORT + 1
SoundStar_DATA: equ SoundStar_BASE_PORT + 0

	org 4000H

page12:
	ds 8000H, 0
	ds 8000H, 0

	SECTION page12

	db "AB"
	dw ROM_Main
	dw ROM_CallEntry
	dw 0, 0, 0, 0, 0

	db "SAA1099", 0  ; ID
	dw 0001H         ; Version
	db "SuperSoniqs SoundStar", 0

ROM_Main:
	ei
	call Reset
	jr ROM_Boombox

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

ROM_Boombox:
	call ROM_SelectRAM
	ret nc
	ld hl,RAM_source
	ld de,RAM_destination
	ld bc,RAM_size
	ldir
	ld ix,ROM_boombox
	call Boombox_Construct
	call Boombox_Run
	call Boombox_Destruct
	jp Reset

; f <- c: found
ROM_SelectRAM:
	call ROM_DetectRAMInCurrentSlot
	ret c
	ld hl,ROM_DetectRAMInSlot
	jp Memory_SearchSlots

; a = slot ID
; f <- c: found
ROM_DetectRAMInSlot:
	ld h,80H
	call Memory_SetSlot
	jr ROM_DetectRAMInCurrentSlot

; f <- c: found
ROM_DetectRAMInCurrentSlot: PROC
	ld hl,8000H
	ld b,4
Loop:
	ld a,(hl)
	cpl
	ld (hl),a
	cp (hl)
	cpl
	ld (hl),a
	scf
	ccf
	ret nz
	djnz Loop
	scf
	ret
	ENDP

; hl = BASIC code pointer
; hl <- BASIC code pointer
ROM_CallEntry: PROC
	ei
	push hl
	ld hl,PROCNM
	ld de,callName
	ld bc,callNameLength
Loop:
	ld a,(de)
	inc de
	cpi
	jr nz,NoMatch
	jp pe,Loop
	ld a,(hl)
	and a
	jr z,Match
NoMatch:
	pop hl
	scf
	ret
Match:
	call ROM_Boombox
	pop hl
	ld hl,(TXTTAB)
	dec hl
	push hl
	ld (hl),0  ; clear program
	inc hl     ; (anything there before will be corrupted)
	ld (hl),0
	inc hl
	ld (hl),0
	pop hl
	and a
	ret
callName:
	db "SOUNDSTAR"
callNameLength: equ $ - callName
	ENDP

	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "Boombox.asm"
	INCLUDE "LZ4Decoder.asm"
	INCLUDE "Module.asm"
	INCLUDE "Player.asm"
	INCLUDE "Graphics.asm"
	INCLUDE "Reels.asm"
	INCLUDE "VUMeters.asm"
	INCLUDE "Controls.asm"

	SECTION RAM

ROM_boombox:
	Boombox

ETCPlayer_BUGFIX: equ 1
ETCPlayer_SAA_OUTPUT: equ 0

	INCLUDE "ETCPlayer.asm"

	ENDS

RAM_source:
	org 0C000H
RAM_destination:
RAM: ds 500H
RAM_size: equ $ - RAM_destination
	org RAM_source + RAM_size

	IF $ >= 8000H
	ERROR "Exceeded page 1."
	ENDIF

	INCLUDE "ModuleData.asm"

	ENDS
