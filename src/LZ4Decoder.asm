;
; LZ4 decoder
;
LZ4Decoder_buffer: equ 0C800H
LZ4Decoder_bufferSize: equ 800H

LZ4Decoder: MACRO
	romSlot:
		db 0
	ramSlot:
		db 0
	ENDM

; ix = this
LZ4Decoder_Construct:
	ld h,40H
	call Memory_GetSlot
	ld (ix + LZ4Decoder.romSlot),a
	ld h,80H
	call Memory_GetSlot
	ld (ix + LZ4Decoder.ramSlot),a
	ret

; ix = this
LZ4Decoder_Destruct:
	ret

; hl = source (ROM)
; ix = this
; hl <- destination (RAM)
; bc <- byte count
LZ4Decoder_Decode: PROC
	ld a,(ix + LZ4Decoder.romSlot)
	call LZ4Decoder_SetSlotPage2
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	inc bc
	inc bc
	push hl
	add hl,bc
	bit 7,h
	pop hl
	jr z,NoCopyNeeded
	push hl
	ld hl,8000H + 4000H
	and a
	sbc hl,bc
	ex de,hl
	pop hl
	call LZ4Decoder_CopyROMToRAM
NoCopyNeeded:
	ld a,(ix + LZ4Decoder.ramSlot)
	call LZ4Decoder_SetSlotPage2
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	push bc
	exx
	pop bc
	ld hl,0
	and a
	sbc hl,bc
	exx
	ld de,8000H
	push de
	push bc
	call LZ4Decoder_DecodeBlock
	pop bc
	pop hl
	ret
	ENDP

; hl = source (ROM)
; de = destination (RAM)
; bc = size
; ix = this
; hl <- destination (RAM)
LZ4Decoder_CopyROMToRAM: PROC
	push de
	call Loop
	pop hl
	ret
Loop:
	ld a,b
	sub LZ4Decoder_bufferSize >> 8
	jr c,Remainder
	ld b,a
	push bc
	ld bc,LZ4Decoder_bufferSize
	call LZ4Decoder_CopyROMToTemp
	call LZ4Decoder_CopyTempToRAM
	pop bc
	jr Loop
Remainder:
	ld a,b
	or c
	ret z
	call LZ4Decoder_CopyROMToTemp
	call LZ4Decoder_CopyTempToRAM
	ret
	ENDP

; hl = source
; bc = size
; ix = this
; hl <- source + size
LZ4Decoder_CopyROMToTemp:
	ld a,(ix + LZ4Decoder.romSlot)
	call LZ4Decoder_SetSlotPage2
	push bc
	push de
	ld de,LZ4Decoder_buffer
	ldir
	pop de
	pop bc
	ret

; de = destination
; bc = size
; ix = this
; de <- destination + size
LZ4Decoder_CopyTempToRAM:
	ld a,(ix + LZ4Decoder.ramSlot)
	call LZ4Decoder_SetSlotPage2
	push bc
	push hl
	ld hl,LZ4Decoder_buffer
	ldir
	pop hl
	pop bc
	ret

; a = slot
LZ4Decoder_SetSlotPage2:
	push bc
	push de
	push hl
	ld h,80H
	call Memory_SetSlot
	pop hl
	pop de
	pop bc
	ret

; hl = source
; de = destination
; hl' = 0 - byte count (decompressed)
LZ4Decoder_DecodeBlock: PROC
	jr Token
Match:
	pop af
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	push hl
	ld l,e
	ld h,d
	and 00FH
	sbc hl,bc
	ex (sp),hl
	ld bc,4
	call Length
	ex (sp),hl
	ldir
	pop hl
Token:
	ld a,(hl)
	inc hl
	push af
	and 0F0H
	jr z,Match
Literal:
	rrca
	rrca
	rrca
	rrca
	ld bc,0
	call Length
	ldir
	jr nc,Match
	pop af
	ret

; hl = source position
; hl <- source position
; bc <- length
; f <- z: data end reached / c: no data remaining
Length:
	cp 15
	call z,LongLength
	add a,c
	ld c,a
	jr nc,LengthRemaining
	inc b
LengthRemaining:
	push bc
	exx
	pop bc
	add hl,bc
	exx
	ret

LongLength:
	add a,c
	ld c,a
LongLengthLoop:
	ld a,(hl)
	inc hl
	cp 255
	ret nz
	inc b
	dec bc
	jr LongLengthLoop
	ENDP
