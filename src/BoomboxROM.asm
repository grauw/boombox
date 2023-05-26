;
; SoundStar ROM
;
SoundStar_BASE_PORT: equ 04H
SoundStar_ADDRESS: equ SoundStar_BASE_PORT + 1
SoundStar_DATA: equ SoundStar_BASE_PORT + 0

	org 4000H

page12:
	ds 8000H, 0

	SECTION page12

	db "AB"
	dw ROM_Main
	dw 0, 0, 0, 0, 0, 0

ROM_Main:
	ei
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
	call ROM_DetectSoundStar
	ret nc
	call ROM_SelectRAM
	ret nc
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

; f <- c: found
ROM_DetectSoundStar:
	ld hl,ROM_DetectSoundStarInSlot
	jp Memory_SearchSlots

; a = slot ID
; f <- c: found
ROM_DetectSoundStarInSlot: PROC
	ld hl,4010H
	ld de,id
	ld bc,7
	jp Memory_MatchSlotString
id:
	db "SAA1099"
	ENDP

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
