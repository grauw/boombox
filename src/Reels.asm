;
; The star-shaped tape reels
;
Reels: MACRO
	position:
		db 0
	increment:
		db -08H
	spriteAttributes:
		db 72, 48, 0, 8
		db 72, 64, 4, 8
		db 88, 48, 8, 8
		db 88, 64, 12, 8
		db 72, 176, 0, 8
		db 72, 192, 4, 8
		db 88, 176, 8, 8
		db 88, 192, 12, 8
		db 208
	ENDM

; ix = this
Reels_Construct:
	ld a,(RG1SAV)
	set 1,a
	ld b,a
	ld c,1
	call WRTVDP
	ret

; ix = this
Reels_Destruct:
	ret

; ix = this
Reels_Tick:
	call Reels_Draw
	ld a,(ix + Reels.position)
	add a,(ix + Reels.increment)
	ld (ix + Reels.position),a
	ret

; ix = this
Reels_Draw:
	ld a,(ix + Reels.position)
	and 0F0H
	ld (ix + Reels.spriteAttributes + 2),a
	ld (ix + Reels.spriteAttributes + 18),a
	add a,4
	ld (ix + Reels.spriteAttributes + 6),a
	ld (ix + Reels.spriteAttributes + 22),a
	add a,4
	ld (ix + Reels.spriteAttributes + 10),a
	ld (ix + Reels.spriteAttributes + 26),a
	add a,4
	ld (ix + Reels.spriteAttributes + 14),a
	ld (ix + Reels.spriteAttributes + 30),a
	ret

; ix = this
Reels_Render:
	push ix
	pop hl
	ld bc,Reels.spriteAttributes
	add hl,bc
	ld de,Graphics_SPRITE_ATTRIBUTE_TABLE
	ld bc,33
	call LDIRVM
	ret
