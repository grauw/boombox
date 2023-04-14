;
; Memory and slot-related routines
;

; h = memory address high byte (bits 6-7: page)
; a <- slot ID formatted F000SSPP
; Modifies: f, bc, de
Memory_GetSlot: PROC
	call RSLREG
	bit 7,h
	jr z,PrimaryShiftContinue
	rrca
	rrca
	rrca
	rrca
PrimaryShiftContinue:
	bit 6,h
	jr z,PrimaryShiftDone
	rrca
	rrca
PrimaryShiftDone:
	and 00000011B
	ld c,a
	ld b,0
	ex de,hl
	ld hl,EXPTBL
	add hl,bc
	ex de,hl
	ld a,(de)
	and 80H
	or c
	ret p
	ld c,a
	inc de  ; move to SLTTBL
	inc de
	inc de
	inc de
	ld a,(de)
	bit 7,h
	jr z,SecondaryShiftContinue
	rrca
	rrca
	rrca
	rrca
SecondaryShiftContinue:
	bit 6,h
	jr nz,SecondaryShiftDone
	rlca
	rlca
SecondaryShiftDone:
	and 00001100B
	or c
	ret
	ENDP

; Sets a slot in the page specified by h.
; The current interrupt enabled state is preserved.
; a = slot ID formatted FxxxSSPP
; h = memory page (40H <= h < C0H)
; Modifies: af, bc, de
Memory_SetSlot:
	ld b,a
	call System_CheckEIState
	ld a,b
	jp po,ENASLT
	call ENASLT
	ei
	ret

; Search all slots and subslots for a match.
; Invoke Continue to continue searching where a previous search left off.
; hl = detection routine (receives a = slot ID, can modify all)
; f <- c: found
; a <- slot number
; Modifies: af, bc, de
Memory_SearchSlots: PROC
	ld a,0
PrimaryLoop:
	ex de,hl
	ld hl,EXPTBL
	ld b,0
	ld c,a
	add hl,bc
	ld a,(hl)
	ex de,hl
	and 10000000B
	or c
SecondaryLoop:
	push af
	push hl
	call System_JumpHL
	pop hl
	jp c,Found
	pop af
Continue:
	add a,00000100B
	jp p,NextPrimary
	bit 4,a
	jp z,SecondaryLoop
NextPrimary:
	inc a
	and 00000011B
	ret z  ; not found
	jp PrimaryLoop
Found:
	pop af
	scf
	ret
	ENDP
