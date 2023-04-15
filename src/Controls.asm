;
;
;
Controls_TRACKS: equ 6
Controls_SIDES: equ (Controls_TRACKS + 2) / 3

Controls_PATTERN_BLANK: equ " " + 96
Controls_PATTERN_PLAY: equ ">" + 96
Controls_PATTERN_PAUSE: equ "#" + 96

Controls_STATUS_PLAYING: equ 0
Controls_STATUS_EXIT: equ 6

Controls: MACRO
	playlist:
		dw 0
	status:
		db 0
	selection:
		db 0
	playing:
		db -1
	ENDM

; hl = playlist
; ix = this
Controls_Construct:
	ld (ix + Controls.playlist + 0),l
	ld (ix + Controls.playlist + 1),h
	ret

; ix = this
Controls_Destruct:
	ret

; a = module number
; ix = this
; iy <- module
Controls_GetModule_IY: PROC
	ld e,a
	ld d,0
	ld l,(ix + Controls.playlist + 0)
	ld h,(ix + Controls.playlist + 1)
	ld b,Module._size
Loop:
	add hl,de
	djnz Loop
	push hl
	pop iy
	ret
	ENDP

; ix = this
Controls_Tick:
	call Controls_HandleInput
	call Controls_Draw
	ret

; ix = this
Controls_HandleInput: PROC
Loop:
	call CHSNS
	ret z
	call Get
	jr Loop
Get:
	call CHGET
	cp 30
	jp z,Controls_Previous
	cp 31
	jp z,Controls_Next
	cp 29
	jp z,Controls_PreviousSide
	cp 28
	jp z,Controls_NextSide
	cp 32
	jp z,Controls_PlayPause
	cp 27
	jp z,Controls_Exit
	cp 8
	jp z,Controls_Stop
	cp 24
	jp z,Controls_ToggleFrequency
	ret
	ENDP

; ix = this
Controls_Previous:
	ld a,(ix + Controls.selection)
	dec a
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	add a,Controls_TRACKS
	ld (ix + Controls.selection),a
	ret

; ix = this
Controls_Next:
	ld a,(ix + Controls.selection)
	inc a
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	sub Controls_TRACKS
	ld (ix + Controls.selection),a
	ret

; ix = this
Controls_PreviousSide:
	ld a,(ix + Controls.selection)
	sub 3
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	add a,Controls_SIDES * 3
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	ld (ix + Controls.selection),Controls_TRACKS - 1
	ret

; ix = this
Controls_NextSide:
	ld a,(ix + Controls.selection)
	add a,3
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	sub Controls_SIDES * 3
	ld (ix + Controls.selection),a
	cp Controls_TRACKS
	ret c
	ld (ix + Controls.selection),Controls_TRACKS - 1
	ret

; ix = this
Controls_PlayPause:
	ld a,(ix + Controls.selection)
	cp (ix + Controls.playing)
	jr nz,Controls_Play
	bit Controls_STATUS_PLAYING,(ix + Controls.status)
	jr nz,Controls_Pause
	jr Controls_Resume

; a = module number
; ix = this
Controls_Play:
	set Controls_STATUS_PLAYING,(ix + Controls.status)
	ld (ix + Controls.playing),a
	ret

; ix = this
Controls_Resume:
	set Controls_STATUS_PLAYING,(ix + Controls.status)
	ret

; ix = this
Controls_Pause:
	res Controls_STATUS_PLAYING,(ix + Controls.status)
	ret

; ix = this
Controls_Stop:
	res Controls_STATUS_PLAYING,(ix + Controls.status)
	ld (ix + Controls.playing),-1
	ret

; ix = this
Controls_Exit:
	set Controls_STATUS_EXIT,(ix + Controls.status)
	call Controls_Stop
	ret

; ix = this
Controls_ToggleFrequency:
	ld a,(IDBYT2)
	and a
	ret z
	ld a,(RG9SAV)
	xor 2
	ld b,a
	ld c,9
	call WRTVDP
	ret

; ix = this
Controls_Draw: PROC
	ld c,(ix + Controls.selection)
	ld a,c
SideLoop:
	sub 3
	jr nc,SideLoop
	add a,3
	sub c
	neg
	ld c,a
	ld b,3
	ld hl,Graphics_nameTableBuffer + 14 * 32 + 10
NameLoop:
	push bc
	push hl
	push hl
	ld a,c
	call Controls_GetModule_IY
	pop hl
	call Controls_DrawModuleName
	pop hl
	ld bc,32
	add hl,bc
	pop bc
	inc c
	djnz NameLoop
	ret
	ENDP

; a = module number
; hl = name table buffer
; iy = module
; ix = this
Controls_DrawModuleName: PROC
	ld c,a
	ld a,(ix + Controls.selection)
	ld (hl),Controls_PATTERN_BLANK
	cp c
	jr nz,Continue
	ld (hl),Controls_PATTERN_PLAY
	cp (ix + Controls.playing)
	jr nz,Continue
	bit Controls_STATUS_PLAYING,(ix + Controls.status)
	jr z,Continue
	ld (hl),Controls_PATTERN_PAUSE
Continue:
	inc hl
	inc hl
	ld e,(iy + Module.name + 0)
	ld d,(iy + Module.name + 1)
	ld b,14
Loop:
	ld a,(de)
	and a
	jr z,End
	inc de
	add a,96
	ld (hl),a
	inc hl
	djnz Loop
	ret
End:
	ld (hl)," " + 96
	inc hl
	djnz End
	ret
	ENDP

; ix = this
Controls_Render:
	ld hl,Graphics_nameTableBuffer + 14 * 32
	ld de,Graphics_NAME_TABLE + 14 * 32
	ld bc,3 * 32
	call LDIRVM
	ret
