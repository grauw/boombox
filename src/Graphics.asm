;
;
;
Graphics_NAME_TABLE: equ 1800H
Graphics_COLOR_TABLE: equ 2000H
Graphics_PATTERN_TABLE: equ 0000H
Graphics_SPRITE_ATTRIBUTE_TABLE: equ 1B00H
Graphics_SPRITE_PATTERN_TABLE: equ 3800H

Graphics_nameTableBuffer: equ 0C500H
Graphics_playlistBuffer: equ 0D000H

Graphics: MACRO
	originalForegroundColor:
		db 0
	originalBackgroundColor:
		db 0
	originalBorderColor:
		db 0
	ENDM

; de = LZ4 decoder
; ix = this
Graphics_Construct:
	push de
	ld hl,Graphics_NAME_TABLE
	ld (GRPNAM),hl
	ld hl,Graphics_COLOR_TABLE
	ld (GRPCOL),hl
	ld hl,Graphics_PATTERN_TABLE
	ld (GRPCGP),hl
	ld hl,Graphics_SPRITE_ATTRIBUTE_TABLE
	ld (GRPATR),hl
	ld hl,Graphics_SPRITE_PATTERN_TABLE
	ld (GRPPAT),hl
	ld a,(FORCLR)
	ld (ix + Graphics.originalForegroundColor),a
	ld a,(BAKCLR)
	ld (ix + Graphics.originalBackgroundColor),a
	ld a,(BDRCLR)
	ld (ix + Graphics.originalBorderColor),a
	ld a,15
	ld (FORCLR),a
	xor a
	ld (BAKCLR),a
	ld (BDRCLR),a
	call INIGRP
	call DISSCR
	ex (sp),ix
	ld hl,Graphics_data
	call LZ4Decoder_Decode
	ld de,0
	call LDIRVM
	ld a,(IDBYT2)
	and a
	push ix
	ld ix,SUB_RSTPLT
	call nz,EXTROM  ; if MSX2 or up
	ei
	pop ix
	ld hl,Graphics_NAME_TABLE
	ld de,Graphics_nameTableBuffer
	ld bc,300H
	call LDIRMV
	ld hl,Graphics_playlistData
	call LZ4Decoder_Decode
	ld de,Graphics_playlistBuffer
	ldir
	pop ix
	ret

; ix = this
Graphics_Destruct:
	call DISSCR
	ld a,(IDBYT2)
	and a
	push ix
	ld ix,SUB_INIPLT
	call nz,EXTROM  ; if MSX2 or up
	pop ix
	ld a,(ix + Graphics.originalForegroundColor)
	ld (FORCLR),a
	ld a,(ix + Graphics.originalBackgroundColor)
	ld (BAKCLR),a
	ld a,(ix + Graphics.originalBorderColor)
	ld (BDRCLR),a
	ret

Graphics_data:
	INCBIN "graphics.lz4"
Graphics_playlistData:
	INCBIN "playlist.lz4"
