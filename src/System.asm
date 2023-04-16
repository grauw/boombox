; hl = jump address
System_JumpHL:
	jp hl

; Workaround for LD A,I / LD A,R lying to us if an interrupt occurs during the
; instruction. We detect this by examining if (sp - 1) was overwritten.
; f: pe <- interrupts enabled
; Modifies: af
System_CheckEIState:
	xor a
	push af  ; set (sp - 1) to 0
	pop af
	ld a,r
	ret pe  ; interrupts enabled? return with pe
	dec sp
	dec sp  ; check whether the Z80 lied about ints being disabled
	pop af  ; (sp - 1) is overwritten w/ MSB of ret address if an ISR occurred
	sub 1
	sbc a,a
	and 1  ; (sp - 1) is not 0? return with pe, otherwise po
	ret

; a <- frequency (0: 60 Hz, 1: 50 Hz)
; f <- frequency (z: 60 Hz, nz: 50 Hz)
System_GetFrequency: PROC
	ld a,(IDBYT2)
	and a
	jr nz,MSX2
	ld a,(IDBYT0)
	rlca
	and 1
	ret
MSX2:
	ld a,(RG9SAV)
	rrca
	and 1
	ret
	ENDP

; a = frequency (0: 60 Hz, 1: 50 Hz)
; f <- c: succeeded
System_SetFrequency:
	and 1
	add a,a
	ld b,a
	ld a,(IDBYT2)
	and a
	ret z
	ld a,(RG9SAV)
	and ~2
	or b
	ld b,a
	ld c,9
	call WRTVDP
	scf
	ret
