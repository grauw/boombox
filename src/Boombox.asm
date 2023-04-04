;
;
;
Boombox_STATUS_WAIT_RESET: equ 0

Boombox: MACRO
	status:
		db 0
	lastJiffy:
		db 0
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
	call Boombox_GetReels
	call Reels_Construct
	pop ix
	push ix
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
Boombox_Run:
	push ix
	ld hl,Module1_data
	call ETCPlayer_Initialize
	pop ix
	set Boombox_STATUS_WAIT_RESET,(ix + Boombox.status)
Boombox_Loop_Outer:
	ld b,5
	ld hl,IDBYT0
	bit 7,(hl)
	jr nz,Boombox_Loop
	call Boombox_WaitTick
Boombox_Loop:
	push bc
	call Boombox_Tick
	call Boombox_WaitTick
	call Boombox_Render
	call CHSNS
	pop bc
	ret nz
	djnz Boombox_Loop
	jr Boombox_Loop_Outer

; ix = this
Boombox_Tick:
	push ix
	call ETCPlayer_Tick
	pop ix
	push ix
	call Boombox_GetReels
	call Reels_Tick
	pop ix
	push ix
	call Boombox_GetVUMeters
	ld iy,ETCPlayer_registers
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
	call Boombox_GetReels
	call Reels_Render
	pop ix
	push ix
	call Boombox_GetVUMeters
	call VUMeters_Render
	pop ix
	ret
