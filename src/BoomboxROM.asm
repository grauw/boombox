;
; Boombox ROM
;
SoundStar_BASE_PORT: equ 04H
SoundStar_ADDRESS: equ SoundStar_BASE_PORT + 1
SoundStar_DATA: equ SoundStar_BASE_PORT + 0

	org 4000H

page1:
	ds 4000H, 0
page2:
	ds 4000H, 0

	SECTION page1

	db "AB"
	dw Main
	dw 0, 0, 0, 0, 0, 0

Main:
	call Reset
	call Player
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

Player:
	ld hl,Module1_data
	ld de,8000H
	ld bc,Module1_length
	ldir
	ld a,05H
	ld (8105H),a
	ld (845AH),a
	ld a,0DH  ; dec c
	ld (810CH),a
	ld (8117H),a
	ld (845EH),a
	ld a,0CH  ; inc c
	ld (8114H),a
	call 8000H
	ei
Player_Loop_Outer:
	ld b,5
	ld hl,002BH
	bit 7,(hl)
	jr nz,Player_Loop
	halt
Player_Loop:
	halt
	push bc
	call 8006H
	pop bc
	call 009CH  ; CHSNS
	ret nz
	djnz Player_Loop
	jr Player_Loop_Outer


Module1_data:
	INCBIN "../res/Pyramex - Electron (2018).etc"
Module1_length: equ $ - Module1_data

	ENDS
