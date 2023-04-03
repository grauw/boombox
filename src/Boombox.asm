;
;
;
Boombox_STATUS_WAIT_RESET: equ 0

Boombox: MACRO
	status:
		db 0
	lastJiffy:
		db 0
	lz4Decoder:
		LZ4Decoder
	player:
		Player
	reels:
		Reels
	vuMeters:
		VUMeters
	ENDM

; ix = this
Boombox_Construct:
	ld a,(FORCLR)
	ld hl,(BAKCLR)
	push af
	push hl
	ld a,15
	ld hl,0
	ld (FORCLR),a
	ld (BAKCLR),hl
	call INIGRP
	pop hl
	pop af
	ld (FORCLR),a
	ld (BAKCLR),hl
	push ix
	call Boombox_GetLZ4Decoder
	call LZ4Decoder_Construct
	ld hl,Boombox_graphics
	call LZ4Decoder_Decode
	ld de,0
	call LDIRVM
	pop ix
	push ix
	ld hl,Module_playlist
	call Boombox_GetLZ4Decoder_DE
	call Boombox_GetPlayer
	call Player_Construct
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Construct
	pop ix
	push ix
	call Boombox_GetPlayer_DE
	call Boombox_GetVUMeters
 	call VUMeters_Construct
	pop ix
	ret

; ix = this
Boombox_Destruct:
	push ix
	call Boombox_GetVUMeters
	call VUMeters_Destruct
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Destruct
	pop ix
	push ix
	call Boombox_GetPlayer
	call Player_Destruct
	pop ix
	push ix
	call Boombox_GetLZ4Decoder
	call LZ4Decoder_Destruct
	pop ix
	ret

; ix = this
; ix <- LZ4 decoder
Boombox_GetLZ4Decoder:
	ld bc,Boombox.lz4Decoder
	add ix,bc
	ret

; ix = this
; de <- LZ4 decoder
Boombox_GetLZ4Decoder_DE:
	push ix
	ld de,Boombox.lz4Decoder
	add ix,de
	ex (sp),ix
	pop de
	ret

; ix = this
; ix <- player
Boombox_GetPlayer:
	ld bc,Boombox.player
	add ix,bc
	ret

; ix = this
; de <- player
Boombox_GetPlayer_DE:
	push ix
	ld de,Boombox.player
	add ix,de
	ex (sp),ix
	pop de
	ret

; ix = this
; ix <- reels
Boombox_GetReels:
	ld bc,Boombox.reels
	add ix,bc
	ret

; ix = this
; ix <- VU meters
Boombox_GetVUMeters:
	ld bc,Boombox.vuMeters
	add ix,bc
 	ret

; ix = this
Boombox_Run: PROC
	push ix
	call Boombox_GetPlayer
	ld a,5
	call Player_Load
	call Player_Play
	pop ix
	set Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
Loop:
	call Boombox_Tick
	call Boombox_WaitTick
	call Boombox_Render
	call CHSNS
	ret nz
	jr Loop
	ENDP

; ix = this
Boombox_Tick:
	push ix
	call Boombox_GetPlayer
	call Player_Tick
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Tick
	pop ix
	push ix
	call Boombox_GetVUMeters
	call VUMeters_Tick
	pop ix
	ret

; ix = this
Boombox_WaitTick:
	call Boombox_WaitFrame
	dec a
	ret z
	dec (ix + Boombox.lastJiffy)
	ret

; ix = this
; a <- frame delta
Boombox_WaitFrame: PROC
	ld a,(ix + Boombox.lastJiffy)
	bit Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
	jr z,Continue
	res Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
	ld a,(JIFFY)
Continue:
	ld c,a
Loop:
	ld a,(JIFFY)
	ld (ix + Boombox.lastJiffy),a
	sub c
	jr z,Loop
	ret
	ENDP

; ix = this
Boombox_Render:
	push ix
	call Boombox_GetPlayer
	call Player_Render
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Render
	pop ix
	push ix
	call Boombox_GetVUMeters
	call VUMeters_Render
	pop ix
	ret

Boombox_graphics:
	INCBIN "graphics.lz4"
