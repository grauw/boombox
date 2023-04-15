;
;
;
Boombox_STATUS_WAIT_RESET: equ 0

Boombox: MACRO
	status:
		db 0
	originalClickSwitch:
		db 0
	lastJiffy:
		db 0
	lz4Decoder:
		LZ4Decoder
	player:
		Player
	graphics:
		Graphics
	reels:
		Reels
	vuMeters:
		VUMeters
	controls:
		Controls
	ENDM

; ix = this
Boombox_Construct:
	ld a,(CLIKSW)
	ld (ix + Boombox.originalClickSwitch),a
	xor a
	ld (CLIKSW),a
	push ix
	call Boombox_GetLZ4Decoder
	call LZ4Decoder_Construct
	pop ix
	push ix
	ld hl,Module_playlist
	call Boombox_GetLZ4Decoder_DE
	call Boombox_GetPlayer
	call Player_Construct
	pop ix
	push ix
	call Boombox_GetLZ4Decoder_DE
	call Boombox_GetGraphics
	call Graphics_Construct
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
	push ix
	ld hl,Module_playlist
	call Boombox_GetControls
	call Controls_Construct
	pop ix
	call ENASCR
	ret

; ix = this
Boombox_Destruct:
	push ix
	call Boombox_GetControls
	call Controls_Destruct
	pop ix
	push ix
	call Boombox_GetVUMeters
	call VUMeters_Destruct
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Destruct
	pop ix
	push ix
	call Boombox_GetGraphics
	call Graphics_Destruct
	pop ix
	push ix
	call Boombox_GetPlayer
	call Player_Destruct
	pop ix
	push ix
	call Boombox_GetLZ4Decoder
	call LZ4Decoder_Destruct
	pop ix
	ld a,(ix + Boombox.originalClickSwitch)
	ld (CLIKSW),a
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
; ix <- graphics
Boombox_GetGraphics:
	ld bc,Boombox.graphics
	add ix,bc
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
; ix <- controls
Boombox_GetControls:
	ld bc,Boombox.controls
	add ix,bc
	ret

; ix = this
Boombox_Run: PROC
	set Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
Loop:
	call Boombox_Tick
	call Boombox_WaitTick
	call Boombox_Render
	bit Controls_STATUS_EXIT,(ix + Boombox.controls.status)
	jr z,Loop
	ret
	ENDP

; ix = this
Boombox_Tick:
	call Boombox_TryLoad
	push ix
	call Boombox_GetControls
	call Controls_Tick
	pop ix
	call Boombox_UpdatePlayer
	push ix
	call Boombox_GetPlayer
	call Player_Tick
	pop ix
	call Boombox_GetReelsIncrement
	ld (ix + Boombox.reels.increment),a
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
Boombox_TryLoad:
	bit Player_STATUS_PLAYING,(ix + Boombox.player.status)
	ret nz
	ld a,(ix + Boombox.controls.playing)
	cp (ix + Boombox.player.loaded)
	ret z
	set Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
	push ix
	call Boombox_GetPlayer
	call Player_Load
	pop ix
	ret

; ix = this
Boombox_UpdatePlayer: PROC
	ld a,(ix + Boombox.controls.playing)
	cp (ix + Boombox.player.loaded)
	jr nz,Load
	bit Controls_STATUS_PLAYING,(ix + Boombox.controls.status)
	jr z,Stop
Play:
	bit Player_STATUS_PLAYING,(ix + Boombox.player.status)
	ret nz
	push ix
	call Boombox_GetPlayer
	call Player_Play
	pop ix
	ret
Stop:
	bit Player_STATUS_PLAYING,(ix + Boombox.player.status)
	ret z
	push ix
	call Boombox_GetPlayer
	call Player_Stop
	pop ix
	ret
Load:
	push ix
	call Boombox_GetPlayer
	call Player_Reset
	pop ix
	ret
	ENDP

; ix = this
; a <- increment
Boombox_GetReelsIncrement: PROC
	xor a
	bit Player_STATUS_PLAYING,(ix + Boombox.player.status)
	ret z
	ld b,(ix + Boombox.player.loaded)
	ld c,(ix + Boombox.controls.selection)
	ld a,c
Loop:
	sub 3
	jr nc,Loop
	sub c
	add a,b
	cp -3
	ld a,08H
	ret c
	neg
	ret
	ENDP

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
	push ix
	call Boombox_GetControls
	call Controls_Render
	pop ix
	ret
