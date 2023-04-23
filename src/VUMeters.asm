;
;
;
VUMeters_PATTERN_BLANK: equ 0F3H
VUMeters_PATTERN_LEFT: equ 0F4H
VUMeters_PATTERN_RIGHT: equ 0F8H

VUMeters_STATUS_UPDATED: equ 7

VUMeters: MACRO
	player:
		dw 0
	status:
		db 0
	ENDM

; de = player
; ix = this
VUMeters_Construct:
	ld (ix + VUMeters.player + 0),e
	ld (ix + VUMeters.player + 1),d
	ret

; ix = this
VUMeters_Destruct:
	ret

; ix = this
; ix <- player
VUMeters_GetPlayer:
	ld c,(ix + VUMeters.player + 0)
	ld b,(ix + VUMeters.player + 1)
	push bc
	pop ix
	ret

; ix = this
; iy = SAA1099 registers mirror
VUMeters_Tick: PROC
	push ix
	call VUMeters_GetPlayer
	call Player_GetSAARegisters
	bit Player_STATUS_UPDATED,(ix + Player.status)
	pop ix
	ret nz
	res VUMeters_STATUS_UPDATED,(ix + VUMeters.status)
	push de
	pop iy
	call VUMeters_GetEnabledChannels
	ld hl,Graphics_nameTableBuffer + 9 * 32 + 10
	ld b,6
Loop:
	srl c
	push bc
	ld a,(iy)
	jr c,Continue
	xor a
Continue:
	push af
	and 00FH
	ld d,VUMeters_PATTERN_LEFT
	call VUMeters_DrawVolume
	pop af
	and 0F0H
	rrca
	rrca
	rrca
	rrca
	ld d,VUMeters_PATTERN_RIGHT
	call VUMeters_DrawVolume
	pop bc
	inc iy
	djnz Loop
	ret
	ENDP

; ix = this
; iy = SAA1099 registers mirror
; c <- enabled channel bits
VUMeters_GetEnabledChannels: PROC
	ld a,(iy + 20)
	or (iy + 21)
	ld c,a
	bit 7,(iy + 24)
	jr z,NoEnvelope0
	set 2,c
NoEnvelope0:
	bit 7,(iy + 25)
	jr z,NoEnvelope1
	set 5,c
NoEnvelope1:
	ret
	ENDP

; a = volume (0-15)
; d = base pattern number
; hl = name table buffer location
; ix = this
; hl <- next name table buffer location
VUMeters_DrawVolume: PROC
	ld c,a
	ld b,4
Loop:
	push bc
	dec b
	rlc b
	rlc b
	inc b
	ld a,c
	sub b
	jr nc,NotEmpty
	ld a,VUMeters_PATTERN_BLANK
	jr Continue
NotEmpty:
	cp 4
	jr c,NotFull
	ld a,3
NotFull:
	add a,d
	jr Continue
Continue:
	ld (hl),a
	ld bc,32
	add hl,bc
	pop bc
	djnz Loop
	ld bc,4 * -32 + 1
	add hl,bc
	ret
	ENDP

; ix = this
VUMeters_Render:
	bit VUMeters_STATUS_UPDATED,(ix + VUMeters.status)
	ret nz
	set VUMeters_STATUS_UPDATED,(ix + VUMeters.status)
	ld hl,Graphics_nameTableBuffer + 9 * 32
	ld de,Graphics_NAME_TABLE + 9 * 32
	ld bc,4 * 32
	call LDIRVM
	ret
