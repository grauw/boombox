;
; Module player
;
; Wraps the Etracker player
;
Player_SAA_REGISTER_COUNT: equ 1DH
Player_SAA_ENABLE_RESET: equ 1CH

Player_STATUS_PLAYING: equ 0

Player: MACRO
	status:
		db 0
	frameSkipCounter:
		db 0
	saaRegisters:
		ds Player_SAA_REGISTER_COUNT
	ENDM

; ix = this
Player_Construct:
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),2
	ret

; ix = this
Player_Destruct:
	ret

; ix = this
; de <- SAA registers
Player_GetSAARegisters:
	push ix
	ld de,Player.saaRegisters
	add ix,de
	ex (sp),ix
	pop de
	ret

; hl = module
; ix = this
Player_Initialize:
	ld a,6  ; These do not get reset properly otherwise
	ld (ETCPlayer_Tick_patternStepTime),a
	ld a,0
	ld (ETCChannel_Tick_patternHeight),a
	ld (ETCPlayer_Initialize_songTableLoop),a
	ld (ETCPlayer_Initialize_songTableLoop + 1),a
	push hl
	ld hl,ETCPlayer_registers
	ld de,ETCPlayer_registers + 1
	ld (hl),0
	ld bc,SAARegisters.envelope1 + 1
	ldir
	pop hl
	push ix
	call ETCPlayer_Initialize
	pop ix
	jp Player_CopyRegisters

; ix = this
Player_Play:
	set Player_STATUS_PLAYING,(ix + Player.status)
	ld (ix + Player.frameSkipCounter),6
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),1
	ret

; ix = this
Player_Stop:
	res Player_STATUS_PLAYING,(ix + Player.status)
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),0
	ret

; ix = this
Player_Reset:
	res Player_STATUS_PLAYING,(ix + Player.status)
	ld (ix + Player.saaRegisters + Player_SAA_ENABLE_RESET),2
	ret

; ix = this
Player_Tick: PROC
	bit Player_STATUS_PLAYING,(ix + Player.status)
	ret z
	dec (ix + Player.frameSkipCounter)
	jr z,Skip
Continue:
	push ix
	call ETCPlayer_Tick
	pop ix
	jr Player_CopyRegisters
Skip:
	ld (ix + Player.frameSkipCounter),6
	ld a,(IDBYT2)
	and a
	jr nz,SkipMSX2
SkipMSX1:
	ld a,(IDBYT0)
	and 128
	jr nz,Continue
	ret
SkipMSX2:
	ld a,(RG9SAV)
	and 2
	jr nz,Continue
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
	push ix
	pop hl
	ld bc,Player.saaRegisters + Player_SAA_REGISTER_COUNT - 1
	add hl,bc
	ld bc,Player_SAA_REGISTER_COUNT << 8 | SoundStar_DATA
	ld a,Player_SAA_REGISTER_COUNT
Loop:
	dec a
	out (SoundStar_ADDRESS),a
	outd
	jp nz,Loop
	ret
	ENDP
