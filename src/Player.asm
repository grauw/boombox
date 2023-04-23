;
; Module player
;
; Wraps the Etracker player
;
Player_SAA_REGISTER_COUNT: equ 1DH
Player_SAA_ENABLE_RESET: equ 1CH

Player_STATUS_LOADED: equ 0
Player_STATUS_PLAYING: equ 1
Player_STATUS_UPDATED: equ 7

Player: MACRO
	playlist:
		dw 0
	lz4Decoder:
		dw 0
	status:
		db 0
	loaded:
		db -1
	module:
		dw 0
	frameSkipCounter:
		db 0
	saaRegisters:
		ds Player_SAA_REGISTER_COUNT
	ENDM

; hl = playlist
; de = LZ4 decoder
; ix = this
Player_Construct:
	ld (ix + Player.playlist + 0),l
	ld (ix + Player.playlist + 1),h
	ld (ix + Player.lz4Decoder + 0),e
	ld (ix + Player.lz4Decoder + 1),d
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),2
	ret

; ix = this
Player_Destruct:
	ret

; ix = this
; ix <- module loader
Player_GetLZ4Decoder:
	ld c,(ix + Player.lz4Decoder + 0)
	ld b,(ix + Player.lz4Decoder + 1)
	push bc
	pop ix
	ret

; ix = this
; iy <- module
Player_GetModule_IY: PROC
	ld e,(ix + Player.loaded)
	ld d,0
	ld l,(ix + Player.playlist + 0)
	ld h,(ix + Player.playlist + 1)
	ld b,Module._size
Loop:
	add hl,de
	djnz Loop
	push hl
	pop iy
	ret
	ENDP

; ix = this
; de <- SAA registers
Player_GetSAARegisters:
	push ix
	ld de,Player.saaRegisters
	add ix,de
	ex (sp),ix
	pop de
	ret

; a = module number
; ix = this
Player_Load:
	cp -1
	jr z,Player_Unload
	set Player_STATUS_LOADED,(ix + Player.status)
	ld (ix + Player.loaded),a
	call Player_GetModule_IY
	ld l,(iy + Module.data + 0)
	ld h,(iy + Module.data + 1)
	push ix
	call Player_GetLZ4Decoder
	call LZ4Decoder_Decode
	pop ix
	ld (ix + Player.module + 0),l
	ld (ix + Player.module + 1),h
	jr Player_Initialize

; ix = this
Player_Unload:
	res Player_STATUS_LOADED,(ix + Player.status)
	ld (ix + Player.loaded),-1
	ld (ix + Player.module + 0),0
	ld (ix + Player.module + 1),0
	jr Player_Initialize

; ix = this
Player_Initialize:
	res Player_STATUS_UPDATED,(ix + Player.status)
	ld a,6  ; These do not get reset properly otherwise
	ld (ETCPlayer_Tick_patternStepTime),a
	ld a,0
	ld (ETCChannel_Tick_patternHeight),a
	ld (ETCPlayer_Initialize_songTableLoop),a
	ld (ETCPlayer_Initialize_songTableLoop + 1),a
	ld hl,ETCPlayer_registers
	ld de,ETCPlayer_registers + 1
	ld (hl),0
	ld bc,SAARegisters.envelope1 + 1
	ldir
	ld l,(ix + Player.module + 0)
	ld h,(ix + Player.module + 1)
	push ix
	bit Player_STATUS_LOADED,(ix + Player.status)
	call nz,ETCPlayer_Initialize
	pop ix
	ret

; ix = this
Player_Play:
	set Player_STATUS_PLAYING,(ix + Player.status)
	res Player_STATUS_UPDATED,(ix + Player.status)
	ld (ix + Player.frameSkipCounter),6
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),1
	ret

; ix = this
Player_Stop:
	res Player_STATUS_PLAYING,(ix + Player.status)
	res Player_STATUS_UPDATED,(ix + Player.status)
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),0
	ret

; ix = this
Player_Reset:
	res Player_STATUS_PLAYING,(ix + Player.status)
	res Player_STATUS_UPDATED,(ix + Player.status)
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),2
	ret

; ix = this
Player_Tick: PROC
	bit Player_STATUS_PLAYING,(ix + Player.status)
	jr z,Continue
	dec (ix + Player.frameSkipCounter)
	jr nz,NoSkip
	ld (ix + Player.frameSkipCounter),6
	call System_GetFrequency
	jr z,Continue
NoSkip:
	bit Player_STATUS_LOADED,(ix + Player.status)
	jr z,Continue
	res Player_STATUS_UPDATED,(ix + Player.status)
	push ix
	call ETCPlayer_Tick
	pop ix
Continue:
	bit Player_STATUS_UPDATED,(ix + Player.status)
	call z,Player_CopyRegisters
	ret
	ENDP

; ix = this
Player_CopyRegisters:
	call Player_GetSAARegisters
	ld hl,ETCPlayer_registers
	ld bc,SAARegisters.envelope1 + 1
	ldir
	ret

; ix = this
Player_Render: PROC
	bit Player_STATUS_UPDATED,(ix + Player.status)
	ret nz
	set Player_STATUS_UPDATED,(ix + Player.status)
	ld c,SoundStar_DATA
	bit 0,(ix + Player.saaRegisters + Player_SAA_ENABLE_RESET)
	jr nz,NoMute
	ld a,Player_SAA_ENABLE_RESET
	ld b,(ix + Player.saaRegisters + Player_SAA_ENABLE_RESET)
	out (SoundStar_ADDRESS),a
	out (c),b
NoMute:
	; output in eTracker sequence
	IRP ?register, 00H, 01H, 09H, 08H, 10H, 02H, 03H, 0BH, 0AH, 11H, 04H, 05H, 0DH, 0CH, 12H, 16H, 18H, 19H, 14H, 15H, 1CH
	ld a,?register
	ld b,(ix + Player.saaRegisters + ?register)
	out (SoundStar_ADDRESS),a
	out (c),b
	ENDM
	ret
	ENDP
