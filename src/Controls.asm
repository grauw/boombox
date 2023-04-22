;
;
;
Controls_TRACKS: equ 9
Controls_SIDES: equ (Controls_TRACKS + 2) / 3

Controls_PATTERN_BLANK: equ 0FFH
Controls_PATTERN_PLAY: equ 0FCH
Controls_PATTERN_PAUSE: equ 0FEH

Controls_STATUS_PLAYING: equ 0
Controls_STATUS_EXIT: equ 6
Controls_STATUS_UPDATED: equ 7

Controls: MACRO
	status:
		db 0
	selection:
		db 0
	playing:
		db -1
	frequencyTimer:
		db 0
	ENDM

; ix = this
Controls_Construct:
	ret

; ix = this
Controls_Destruct:
	ret

; a = handle input (0: yes)
; ix = this
Controls_Tick:
	and a
	call z,Controls_HandleInput
	call Controls_Draw
	ret

; ix = this
Controls_HandleInput: PROC
Loop:
	bit Controls_STATUS_EXIT,(ix + Controls.status)
	ret nz
	call CHSNS
	ret z
	call Get
	jr Loop
Get:
	call CHGET
	ld b,(ix + Controls.status)
	res Controls_STATUS_UPDATED,(ix + Controls.status)
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
	ld (ix + Controls.status),b
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
	call System_GetFrequency
	xor 1
	call System_SetFrequency
	call System_GetFrequency
	ld (ix + Controls.frequencyTimer),3 * 60
	ret z
	ld (ix + Controls.frequencyTimer),3 * 50
	ret

; ix = this
Controls_Draw: PROC
	bit Controls_STATUS_UPDATED,(ix + Controls.status)
	ret nz
	ld hl,Graphics_playlistBuffer + 7
	ld b,Controls_PATTERN_PLAY
	call Draw
	ld hl,Graphics_playlistBuffer + 24
	inc b
Draw:
	ld c,0
	ld de,32
Loop:
	ld a,(ix + Controls.selection)
	ld (hl),Controls_PATTERN_BLANK
	cp c
	jr nz,Continue
	ld (hl),b
	cp (ix + Controls.playing)
	jr nz,Continue
	bit Controls_STATUS_PLAYING,(ix + Controls.status)
	jr z,Continue
	ld (hl),Controls_PATTERN_PAUSE
Continue:
	add hl,de
	inc c
	ld a,c
	cp Controls_TRACKS
	jr c,Loop
	ret
	ENDP

; ix = this
Controls_Render:
	call Controls_RenderPlaylist
	call Controls_RenderFrequency
	ret

; ix = this
Controls_RenderPlaylist: PROC
	bit Controls_STATUS_UPDATED,(ix + Controls.status)
	ret nz
	set Controls_STATUS_UPDATED,(ix + Controls.status)
	ld hl,Graphics_playlistBuffer
	ld bc,3 * 32
	ld a,(ix + Controls.selection)
Loop:
	sub 3
	jr c,Continue
	add hl,bc
	jr Loop
Continue:
	ld de,Graphics_NAME_TABLE + 14 * 32
	ld bc,3 * 32
	call LDIRVM
	ret
	ENDP

; ix = this
Controls_RenderFrequency: PROC
	ld a,(ix + Controls.frequencyTimer)
	sub 1
	ret c
	ld (ix + Controls.frequencyTimer),a
	ld hl,Graphics_NAME_TABLE + 22 * 32 + 15
	jr z,Blank
	call System_GetFrequency
	add a,0F8H
	call WRTVRM
	inc hl
	ld a,0FAH
	jp WRTVRM
Blank:
	ld a,0FBH
	call WRTVRM
	inc hl
	ld a,0FBH
	jp WRTVRM
	ENDP
