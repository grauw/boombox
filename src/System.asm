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
