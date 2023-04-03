;
;
;
ETCChannel: MACRO
	track:
		dw 0
	instrument:
		dw 0
	instrumentLoop:
		dw 0
	ornament:
		dw 0
	ornamentLoop:
		dw 0
	instrumentPitch:
		dw 0
	volume:
		db 0
	ornamentNote:
		db 0
	note:
		db 0
	instrumentStart:
		dw 0
	ornamentStart:
		dw 0
	delay_next_note:
		db 0
	next_ornament:
		db 0
	next_instrument:
		db 0
	next_volume:
		db 0
	instrumentInversion:
		db 0
	volumeReduction:
		db 0
	size:
	ENDM

ETCPlayer_Init:
	ld hl,ETCPlayer_soundData    ; #8000 ; !    ; #21,#B3,#84
	jp ETCPlayer_Initialize       ; #8003 ;      ; #C3,#EF,#83

ETCPlayer_Tick:
	LD A,#01        ; #8006 ; >    ; #3E,#01
ETCPlayer_Tick_link_8: equ $ - 1
	DEC A           ; #8008 ; =    ; #3D
	JR NZ,ETCPlayer_Tick_Link_62   ; #8009 ;      ; #20,#1F
	LD IX,ETCPlayer_channel0    ; #800B ;  !=  ; #DD,#21,#3D,#83
	LD B,6        ; #800F ;      ; #06,#06
ETCPlayer_Tick_Link_63:
	PUSH BC         ; #8011 ;      ; #C5
	CALL ETCChannel_TickEffects     ; #8012 ;      ; #CD,#A7,#81
	LD BC,ETCChannel.size     ; #8015 ;      ; #01,#19,#00
	ADD IX,BC       ; #8018 ;      ; #DD,#09
	POP BC          ; #801A ;      ; #C1
	DJNZ ETCPlayer_Tick_Link_63    ; #801B ;      ; #10,#F4
	LD HL,(ETCPlayer_registers._extendedNoise0)  ; #801D ; *    ; #2A,#ED,#83
	LD A,H          ; #8020 ; |    ; #7C
	CALL SwapNibbleA     ; #8021 ;  W   ; #CD,#57,#81
	OR L            ; #8024 ;      ; #B5
	LD (ETCPlayer_Tick_link_7),A   ; #8025 ; 2    ; #32,#E6,#80
	LD A,#06        ; #8028 ; >    ; #3E,#06
ETCPlayer_Tick_patternStepTime: equ $ - 1
ETCPlayer_Tick_Link_62:
	LD (ETCPlayer_Tick_link_8),A   ; #802A ; 2    ; #32,#07,#80

	LD IX,ETCPlayer_channel0    ; #802D ;  !=  ; #DD,#21,#3D,#83
	CALL ETCChannel_Tick     ; #8031 ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude0),A  ; #8034 ; 2    ; #32,#D3,#83
	LD (ETCPlayer_registers.frequency0),HL ; #8037 ; "    ; #22,#DB,#83
	PUSH HL         ; #803A ;      ; #E5
	LD HL,#0000     ; #803B ; !    ; #21,#00,#00
	CALL ETCPlayer_Tick_ShiftEnable    ; #803E ;  \   ; #CD,#5C,#81
	LD (ETCPlayer_Tick_enable0Accu),HL ; #8041 ; "V   ; #22,#56,#80
	LD (ETCPlayer_Tick_noise0),A  ; #8044 ; 2    ; #32,#E4,#80

	LD IX,ETCPlayer_channel1   ; #8047 ;  !V  ; #DD,#21,#56,#83
	CALL ETCChannel_Tick     ; #804B ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude1),A  ; #804E ; 2    ; #32,#D4,#83
	LD (ETCPlayer_registers.frequency1),HL ; #8051 ; "    ; #22,#DC,#83
	PUSH HL         ; #8054 ;      ; #E5
	LD HL,#0000     ; #8055 ; !    ; #21,#00,#00
ETCPlayer_Tick_enable0Accu: equ $ - 2
	CALL ETCPlayer_Tick_ShiftEnable    ; #8058 ;  \   ; #CD,#5C,#81
	LD (ETCPlayer_Tick_enable1Accu),HL ; #805B ; "t   ; #22,#74,#80
	RL H            ; #805E ;      ; #CB,#14
	JR NC,ETCPlayer_Tick_Link_64   ; #8060 ; 0    ; #30,#03
	LD (ETCPlayer_Tick_noise0),A  ; #8062 ; 2    ; #32,#E4,#80
ETCPlayer_Tick_Link_64:
	LD IX,ETCPlayer_channel2   ; #8065 ;  !o  ; #DD,#21,#6F,#83
	CALL ETCChannel_Tick     ; #8069 ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude2),A  ; #806C ; 2    ; #32,#D5,#83
	LD (ETCPlayer_registers.frequency2),HL ; #806F ; "    ; #22,#DD,#83
	PUSH HL         ; #8072 ;      ; #E5
	LD HL,#0000     ; #8073 ; !    ; #21,#00,#00
ETCPlayer_Tick_enable1Accu: equ $ - 2
	CALL ETCPlayer_Tick_ShiftEnable    ; #8076 ;  \   ; #CD,#5C,#81
	LD (ETCPlayer_Tick_enable2Accu),HL ; #8079 ; "    ; #22,#92,#80
	RL H            ; #807C ;      ; #CB,#14
	JR NC,ETCPlayer_Tick_Link_65   ; #807E ; 0    ; #30,#03
	LD (ETCPlayer_Tick_noise0),A  ; #8080 ; 2    ; #32,#E4,#80
ETCPlayer_Tick_Link_65:
	LD IX,ETCPlayer_channel3   ; #8083 ;  !   ; #DD,#21,#88,#83
	CALL ETCChannel_Tick     ; #8087 ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude3),A  ; #808A ; 2    ; #32,#D6,#83
	LD (ETCPlayer_registers.frequency3),HL ; #808D ; "    ; #22,#DE,#83
	PUSH HL         ; #8090 ;      ; #E5
	LD HL,#0000     ; #8091 ; !    ; #21,#00,#00
ETCPlayer_Tick_enable2Accu: equ $ - 2
	CALL ETCPlayer_Tick_ShiftEnable    ; #8094 ;  \   ; #CD,#5C,#81
	LD (ETCPlayer_Tick_enable3Accu),HL ; #8097 ; "    ; #22,#AC,#80
	LD (ETCPlayer_Tick_noise1Accu),A  ; #809A ; 2    ; #32,#DE,#80
	LD IX,ETCPlayer_channel4   ; #809D ;  !   ; #DD,#21,#A1,#83
	CALL ETCChannel_Tick     ; #80A1 ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude4),A  ; #80A4 ; 2    ; #32,#D7,#83
	LD (ETCPlayer_registers.frequency4),HL ; #80A7 ; "    ; #22,#DF,#83
	PUSH HL         ; #80AA ;      ; #E5
	LD HL,0000      ; #80AB ; !    ; #21,#00,#00
ETCPlayer_Tick_enable3Accu: equ $ - 2
	CALL ETCPlayer_Tick_ShiftEnable    ; #80AE ;  \   ; #CD,#5C,#81
	LD (ETCPlayer_Tick_enable4Accu),HL ; #80B1 ; "    ; #22,#CA,#80
	RL H            ; #80B4 ;      ; #CB,#14
	JR NC,ETCPlayer_Tick_Link_66   ; #80B6 ; 0    ; #30,#03
	LD (ETCPlayer_Tick_noise1Accu),A  ; #80B8 ; 2    ; #32,#DE,#80
ETCPlayer_Tick_Link_66:
	LD IX,ETCPlayer_channel5   ; #80BB ;  !   ; #DD,#21,#BA,#83
	CALL ETCChannel_Tick     ; #80BF ;  m   ; #CD,#6D,#82
	LD (ETCPlayer_registers.amplitude5),A  ; #80C2 ; 2    ; #32,#D8,#83
	LD (ETCPlayer_registers.frequency5),HL ; #80C5 ; "    ; #22,#E0,#83
	PUSH HL         ; #80C8 ;      ; #E5
	LD HL,#0000     ; #80C9 ; !    ; #21,#00,#00
ETCPlayer_Tick_enable4Accu: equ $ - 2
	CALL ETCPlayer_Tick_ShiftEnable    ; #80CC ;  \   ; #CD,#5C,#81
	RR L            ; #80CF ;      ; #CB,#1D
	RR L            ; #80D1 ;      ; #CB,#1D
	RR H            ; #80D3 ;      ; #CB,#1C
	RR H            ; #80D5 ;      ; #CB,#1C
	LD (ETCPlayer_registers.frequencyEnable),HL ; #80D7 ; "    ; #22,#E7,#83
	RLCA            ; #80DA ;      ; #07
	JR C,ETCPlayer_Tick_Link_67    ; #80DB ; 8    ; #38,#03
	LD A,#00        ; #80DD ; >    ; #3E,#00
ETCPlayer_Tick_noise1Accu: equ $ - 1
	RLCA            ; #80DF ;      ; #07
ETCPlayer_Tick_Link_67:
	RLCA            ; #80E0 ;      ; #07
	RLCA            ; #80E1 ;      ; #07
	RLCA            ; #80E2 ;      ; #07
	OR #00          ; #80E3 ;      ; #F6,#00
ETCPlayer_Tick_noise0: equ $ - 1
	OR #00          ; #80E5 ;      ; #F6,#00
ETCPlayer_Tick_link_7: equ $ - 1
	LD (ETCPlayer_registers.noise10),A  ; #80E7 ; 2    ; #32,#E9,#83
	POP AF          ; #80EA ;      ; #F1
	POP BC          ; #80EB ;      ; #C1
	CALL SwapNibbleA     ; #80EC ;  W   ; #CD,#57,#81
	OR B            ; #80EF ;      ; #B0
	LD H,A          ; #80F0 ; g    ; #67
	POP AF          ; #80F1 ;      ; #F1
	POP BC          ; #80F2 ;      ; #C1
	CALL SwapNibbleA     ; #80F3 ;  W   ; #CD,#57,#81
	OR B            ; #80F6 ;      ; #B0
	LD L,A          ; #80F7 ; o    ; #6F
	LD (ETCPlayer_registers.octave32),HL ; #80F8 ; "    ; #22,#E4,#83
	POP AF          ; #80FB ;      ; #F1
	POP BC          ; #80FC ;      ; #C1
	CALL SwapNibbleA     ; #80FD ;  W   ; #CD,#57,#81
	OR B            ; #8100 ;      ; #B0
	LD (ETCPlayer_registers.octave10),A  ; #8101 ; 2    ; #32,#E3,#83
	; unmute
	LD BC,ETCPlayer_SAA_ADDRESS_PORT     ; #8104 ;      ; #01,#FF,#01
	LD DE,#1C01     ; #8107 ;      ; #11,#01,#1C
	OUT (C),D       ; #810A ;  Q   ; #ED,#51
	DEC ETCPlayer_SAA_MODE_REG           ; #810C ;      ; #05
	OUT (C),E       ; #810D ;  Y   ; #ED,#59
	; output all channel data (backwards)
	LD HL,ETCPlayer_registers.envelope1   ; #810F ; !    ; #21,#EC,#83
	LD D,SAARegisters.envelope1        ; #8112 ;      ; #16,#19
ETCPlayer_Tick_Link_68:
	INC ETCPlayer_SAA_MODE_REG           ; #8114 ;      ; #04
	OUT (C),D       ; #8115 ;  Q   ; #ED,#51
	DEC ETCPlayer_SAA_MODE_REG           ; #8117 ;      ; #05
	LD A,(HL)       ; #8118 ; ~    ; #7E
	OUT (C),A       ; #8119 ;  y   ; #ED,#79
	DEC D           ; #811B ;      ; #15
	RET M           ; #811C ;      ; #F8
	DEC HL          ; #811D ; +    ; #2B
	JR ETCPlayer_Tick_Link_68      ; #811E ;      ; #18,#F4

ETCChannel_noteFrequency:
	db #05          ; #8120 ;      ; #05
	db #21          ; #8121 ; !    ; #21
	db #3C          ; #8122 ; <    ; #3C
	db #55          ; #8123 ; U    ; #55
	db #6D          ; #8124 ; m    ; #6D
	db #84          ; #8125 ;      ; #84
	db #99          ; #8126 ;      ; #99
	db #AD          ; #8127 ;      ; #AD
	db #C0          ; #8128 ;      ; #C0
	db #D2          ; #8129 ;      ; #D2
	db #E3          ; #812A ;      ; #E3
	db #F3          ; #812B ;      ; #F3

ETCChannel_instrumentNone:
	db #FE          ; #812C ;      ; #FE
	db #01          ; #812D ;      ; #01
	db #00          ; #812E ;      ; #00
	db #00          ; #812F ;      ; #00
	db #FC          ; #8130 ;      ; #FC

ETCChannel_envelopeTable:
	db #00          ; #8131 ;      ; #00
	db #96          ; #8132 ;      ; #96
	db #9E          ; #8133 ;      ; #9E
	db #9A          ; #8134 ;      ; #9A
	db #86          ; #8135 ;      ; #86
	db #8E          ; #8136 ;      ; #8E
	db #8A          ; #8137 ;      ; #8A
	db #97          ; #8138 ;      ; #97
	db #9F          ; #8139 ;      ; #9F
	db #9B          ; #813A ;      ; #9B
	db #87          ; #813B ;      ; #87
	db #8F          ; #813C ;      ; #8F
	db #8B          ; #813D ;      ; #8B

ETCChannel_ornamentNone:
	db #FE          ; #813E ;      ; #FE
	db #00          ; #813F ;      ; #00
	db #FF          ; #8140 ;      ; #FF

; First byte is ignored.
; Every even byte is the start of the range for the effect.
; Every odd byte is a relative jump offset.
ETCChannel_effectsTable:
	db #D2          ; #8141 ;      ; #D2
	db ETCChannel_Effect_D2_FF - ETCChannel_TickEffects_JrRef          ; #8142 ; W    ; #57
	db #72          ; #8143 ; r    ; #72
	db ETCChannel_Effect_72_D1 - ETCChannel_TickEffects_JrRef          ; #8144 ;      ; #00
	db #52          ; #8145 ; R    ; #52
	db ETCChannel_Effect_52_71 - ETCChannel_TickEffects_JrRef          ; #8146 ;      ; #AB
	db #51          ; #8147 ; Q    ; #51
	db ETCChannel_Effect_51 - ETCChannel_TickEffects_JrRef          ; #8148 ; a    ; #61
	db #50          ; #8149 ; P    ; #50
	db ETCChannel_Effect_50 - ETCChannel_TickEffects_JrRef          ; #814A ; R    ; #52
	db #30          ; #814B ; 0    ; #30
	db ETCChannel_Effect_30_4F - ETCChannel_TickEffects_JrRef          ; #814C ;      ; #C2
	db #2E          ; #814D ; .    ; #2E
	db ETCChannel_Effect_2E_2F - ETCChannel_TickEffects_JrRef          ; #814E ; 5    ; #35
	db #21          ; #814F ; !    ; #21
	db ETCChannel_Effect_21_2D - ETCChannel_TickEffects_JrRef          ; #8150 ; )    ; #29
	db #11          ; #8151 ;      ; #11
	db ETCChannel_Effect_11_20 - ETCChannel_TickEffects_JrRef          ; #8152 ; A    ; #41
	db #0F          ; #8153 ;      ; #0F
	db ETCChannel_Effect_0F_10 - ETCChannel_TickEffects_JrRef          ; #8154 ; F    ; #46
	db #00          ; #8155 ;      ; #00
	db ETCChannel_Effect_00_0E - ETCChannel_TickEffects_JrRef          ; #8156 ; :    ; #3A

SwapNibbleA:
	RLCA            ; #8157 ;      ; #07
	RLCA            ; #8158 ;      ; #07
	RLCA            ; #8159 ;      ; #07
	RLCA            ; #815A ;      ; #07
	RET             ; #815B ;      ; #C9

ETCPlayer_Tick_ShiftEnable:
	EX AF, AF'      ; #815C ;      ; #08
	RRCA            ; #815D ;      ; #0F
	RR L            ; #815E ;      ; #CB,#1D
	RRCA            ; #8160 ;      ; #0F
	RR H            ; #8161 ;      ; #CB,#1C
	RET             ; #8163 ;      ; #C9

; c = index
ETCPlayer_GetReferenceAtIndex:
	SLA C           ; #8164 ;  !   ; #CB,#21
	LD B,#00        ; #8166 ;      ; #06,#00
	JR NC,link_70   ; #8168 ; 0    ; #30,#01
	INC B           ; #816A ;      ; #04
link_70:
	ADD HL,BC       ; #816B ;      ; #09
	; fall-through
; ETCPlayer_GetReference_offset = Sound data base address
; hl = Pointer to offset in sound data
; bc <- Offset pointer to sound data
; hl <- Pointer to next value
ETCPlayer_GetReference:
	ld c,(hl)       ; #816C ; N    ; #4E
	inc hl          ; #816D ; #    ; #23
	ld b,(hl)       ; #816E ; F    ; #46
	inc hl          ; #816F ; #    ; #23
	push hl         ; #8170 ;      ; #E5
	ld hl,#0000     ; #8171 ; !    ; #21,#00,#00
ETCPlayer_GetReference_offset: equ $ - 2
	add hl,bc       ; #8174 ;      ; #09
	ld c,l          ; #8175 ; M    ; #4D
	ld b,h          ; #8176 ; D    ; #44
	pop hl          ; #8177 ;      ; #E1
	ret             ; #8178 ;      ; #C9

; ?BUGFIX NEEDED? Some glitch here in Sam n Bass, instrument w/o note retriggers...
; c = instrument
; ix = channel
ETCChannel_Effect_52_71:
	LD HL,#0000     ; #8179 ; !    ; #21,#00,#00
ETCPlayer_instruments: equ $ - 2
	CALL ETCPlayer_GetReferenceAtIndex    ; #817C ;  d   ; #CD,#64,#81
	LD (IX + ETCChannel.instrumentStart + 0),C    ; #817F ;  q   ; #DD,#71,#0F
	LD (IX + ETCChannel.instrumentStart + 1),B    ; #8182 ;  p   ; #DD,#70,#10
	LD HL,ETCChannel_instrumentNone   ; #8185 ; !,   ; #21,#2C,#81
	LD (IX + ETCChannel.instrumentLoop + 0),L     ; #8188 ;  u   ; #DD,#75,#04
	LD (IX + ETCChannel.instrumentLoop + 1),H     ; #818B ;  t   ; #DD,#74,#05
	JR ETCChannel_Effect_72_D1_Link_80      ; #818E ;  G   ; #18,#47

; c = ornament
; ix = channel
ETCChannel_Effect_30_4F:
	LD HL,#0000     ; #8190 ; !    ; #21,#00,#00
ETCPlayer_ornaments: equ $ - 2
	CALL ETCPlayer_GetReferenceAtIndex    ; #8193 ;  d   ; #CD,#64,#81
	LD (IX + ETCChannel.ornamentStart + 0),C    ; #8196 ;  q   ; #DD,#71,#11
	LD (IX + ETCChannel.ornamentStart + 1),B    ; #8199 ;  p   ; #DD,#70,#12
	LD HL,ETCChannel_ornamentNone   ; #819C ; !>   ; #21,#3E,#81
	LD (IX + ETCChannel.ornamentLoop + 0),L     ; #819F ;  u   ; #DD,#75,#08
	LD (IX + ETCChannel.ornamentLoop + 1),H     ; #81A2 ;  t   ; #DD,#74,#09
	JR ETCChannel_Effect_72_D1_Link_72      ; #81A5 ;  <   ; #18,#3C

; b = 6 - channel index
; ix = channel
ETCChannel_TickEffects:
	DEC (IX + ETCChannel.delay_next_note)     ; #81A7 ;  5   ; #DD,#35,#13
	RET P           ; #81AA ;      ; #F0
	LD A,B          ; #81AB ; x    ; #78
	IF ETCPlayer_BUGFIX
	CP #04          ; Fixes noise bug in Vexx Ingame
	ELSE
	CP #03          ; #81AC ;      ; #FE,#03
	ENDIF
	LD HL,ETCPlayer_registers.envelope0   ; #81AE ; !    ; #21,#EB,#83
	JR NC,ETCChannel_TickEffects_Envelope0   ; #81B1 ; 0    ; #30,#01
	INC HL          ; #81B3 ; #    ; #23
ETCChannel_TickEffects_Envelope0:
	LD (ETCChannel_TickEffects_envelope),HL ; #81B4 ; "    ; #22,#FF,#81
ETCChannel_TickEffects_Link_51:
	LD E,(IX + ETCChannel.track + 0)     ; #81B7 ;  ^   ; #DD,#5E,#00
	LD D,(IX + ETCChannel.track + 1)     ; #81BA ;  V   ; #DD,#56,#01
ETCChannel_TickEffects_Link_76:
	LD HL,ETCChannel_effectsTable - 1   ; #81BD ; !@   ; #21,#40,#81
ETCChannel_TickEffects_Link_74:
	LD A,(DE)       ; #81C0 ;      ; #1A
	INC HL          ; #81C1 ; #    ; #23
	SUB (HL)        ; #81C2 ;      ; #96
	INC HL          ; #81C3 ; #    ; #23
	JR C,ETCChannel_TickEffects_Link_74    ; #81C4 ; 8    ; #38,#FA
	INC DE          ; #81C6 ;      ; #13
	LD C,A          ; #81C7 ; O    ; #4F
	LD A,(HL)       ; #81C8 ; ~    ; #7E
	LD (ETCChannel_TickEffects_jrOffset),A  ; #81C9 ; 2    ; #32,#CD,#81
	JR $            ; #81CC ;  W   ; #18,#FE
ETCChannel_TickEffects_jrOffset: equ $ - 1
ETCChannel_TickEffects_JrRef:

; ix = channel
ETCChannel_Effect_72_D1:
	LD (IX + ETCChannel.note),C        ; #81CE ;  q   ; #DD,#71,#0E
	LD C,(IX + ETCChannel.instrumentStart + 0)    ; #81D1 ;  N   ; #DD,#4E,#0F
	LD B,(IX + ETCChannel.instrumentStart + 1)    ; #81D4 ;  F   ; #DD,#46,#10
ETCChannel_Effect_72_D1_Link_80:
	LD (IX + ETCChannel.instrument + 0),C     ; #81D7 ;  q   ; #DD,#71,#02
	LD (IX + ETCChannel.instrument + 1),B     ; #81DA ;  p   ; #DD,#70,#03
	LD C,(IX + ETCChannel.ornamentStart + 0)    ; #81DD ;  N   ; #DD,#4E,#11
	LD B,(IX + ETCChannel.ornamentStart + 1)    ; #81E0 ;  F   ; #DD,#46,#12
ETCChannel_Effect_72_D1_Link_72:
	LD (IX + ETCChannel.ornament + 0),C     ; #81E3 ;  q   ; #DD,#71,#06
	LD (IX + ETCChannel.ornament + 1),B     ; #81E6 ;  p   ; #DD,#70,#07
	LD (IX + ETCChannel.next_ornament),1        ; #81E9 ;  6   ; #DD,#36,#14,#01
	LD (IX + ETCChannel.next_instrument),1        ; #81ED ;  6   ; #DD,#36,#15,#01
	LD (IX + ETCChannel.next_volume),1        ; #81F1 ;  6   ; #DD,#36,#16,#01
	JR ETCChannel_TickEffects_Link_76      ; #81F5 ;      ; #18,#C6

; ix = channel
ETCChannel_Effect_21_2D:
	LD B,#00        ; #81F7 ;      ; #06,#00
	LD HL,ETCChannel_envelopeTable   ; #81F9 ; !1   ; #21,#31,#81
	ADD HL,BC       ; #81FC ;      ; #09
	LD A,(HL)       ; #81FD ; ~    ; #7E
	LD (#0000),A    ; #81FE ; 2    ; #32,#00,#00
ETCChannel_TickEffects_envelope: equ $ - 2
	JR ETCChannel_TickEffects_Link_76      ; #8201 ;      ; #18,#BA

; Enable / disable instrument inversion
; ix = channel
ETCChannel_Effect_2E_2F:
	LD (IX + ETCChannel.instrumentInversion),C    ; #8203 ;  q   ; #DD,#71,#17
	JR ETCChannel_TickEffects_Link_76      ; #8206 ;      ; #18,#B5

; Set pattern step increment time in frames
; ix = channel
ETCChannel_Effect_00_0E:
	LD A,C          ; #8208 ; y    ; #79
	INC A           ; #8209 ; <    ; #3C
	LD (ETCPlayer_Tick_patternStepTime),A  ; #820A ; 2)   ; #32,#29,#80
	JR ETCChannel_TickEffects_Link_76      ; #820D ;      ; #18,#AE

; ix = channel
ETCChannel_Effect_11_20:
	LD (IX + ETCChannel.volumeReduction),C    ; #820F ;  q   ; #DD,#71,#18
	JR ETCChannel_TickEffects_Link_76      ; #8212 ;      ; #18,#A9

; Enable / disable extended noise (frequency generator 0 / 3 controlled)
; ix = channel
ETCChannel_Effect_0F_10:
	JR Z,ETCChannel_Effect_72_D1_Link_79    ; #8214 ; (    ; #28,#02
	LD C,#03        ; #8216 ;      ; #0E,#03
ETCChannel_Effect_72_D1_Link_79:
	LD HL,(ETCChannel_TickEffects_envelope) ; #8218 ; *    ; #2A,#FF,#81
	INC HL          ; #821B ; #    ; #23
	INC HL          ; #821C ; #    ; #23
	LD (HL),C       ; #821D ; q    ; #71
	JR ETCChannel_TickEffects_Link_76      ; #821E ;      ; #18,#9D

; Note off
; ix = channel
ETCChannel_Effect_50:
	LD BC,ETCChannel_instrumentNone   ; #8220 ;  ,   ; #01,#2C,#81
	JR ETCChannel_Effect_72_D1_Link_80      ; #8223 ;      ; #18,#B2

; ix = channel
ETCChannel_Effect_D2_FF:
	LD (IX + ETCChannel.delay_next_note),C    ; #8225 ;  q   ; #DD,#71,#13
	LD (IX + ETCChannel.track + 0),E     ; #8228 ;  s   ; #DD,#73,#00
	LD (IX + ETCChannel.track + 1),D     ; #822B ;  r   ; #DD,#72,#01
	RET             ; #822E ;      ; #C9

; ix = channel
ETCChannel_Effect_51:
	CALL link_50      ; #822F ;  a   ; #CD,#61,#84
	JP ETCChannel_TickEffects_Link_51      ; #8232 ;      ; #C3,#B7,#81

; ix = channel
ETCChannel_Tick_Instrument:
	CP #7F          ; #8235 ;      ; #FE,#7F
	JR Z,ETCChannel_Tick_Instrument_SetLoop    ; #8237 ; (    ; #28,#09
	CP #7E          ; #8239 ;  ~   ; #FE,#7E
	JR Z,ETCChannel_Tick_Instrument_GetLoop    ; #823B ; (    ; #28,#0D
	ADD A,#02       ; #823D ;      ; #C6,#02
	LD C,A          ; #823F ; O    ; #4F
	JR ETCChannel_Tick_Link_83      ; #8240 ;  >   ; #18,#3E

; ix = channel
ETCChannel_Tick_Instrument_SetLoop:
	LD (IX + ETCChannel.instrumentLoop + 0),L     ; #8242 ;  u   ; #DD,#75,#04
	LD (IX + ETCChannel.instrumentLoop + 1),H     ; #8245 ;  t   ; #DD,#74,#05
	JR ETCChannel_Tick_Link_83      ; #8248 ;  6   ; #18,#36

; ix = channel
ETCChannel_Tick_Instrument_GetLoop:
	LD L,(IX + ETCChannel.instrumentLoop + 0)     ; #824A ;  n   ; #DD,#6E,#04
	LD H,(IX + ETCChannel.instrumentLoop + 1)     ; #824D ;  f   ; #DD,#66,#05
	JR ETCChannel_Tick_Link_83      ; #8250 ;  .   ; #18,#2E

; ix = channel
ETCChannel_Tick_Ornament:
	INC A           ; #8252 ; <    ; #3C
	JR Z,ETCChannel_Tick_Ornament_GetLoop    ; #8253 ; (    ; #28,#08
	INC A           ; #8255 ; <    ; #3C
	JR Z,ETCChannel_Tick_Ornament_SetLoop    ; #8256 ; (    ; #28,#0D
	SUB #60         ; #8258 ;  `   ; #D6,#60
	LD C,A          ; #825A ; O    ; #4F
	JR ETCChannel_Tick_Link_88      ; #825B ;  E   ; #18,#45

; ix = channel
ETCChannel_Tick_Ornament_GetLoop:
	LD L,(IX + ETCChannel.ornamentLoop + 0)     ; #825D ;  n   ; #DD,#6E,#08
	LD H,(IX + ETCChannel.ornamentLoop + 1)     ; #8260 ;  f   ; #DD,#66,#09
	JR ETCChannel_Tick_Link_88      ; #8263 ;  =   ; #18,#3D

; ix = channel
ETCChannel_Tick_Ornament_SetLoop:
	LD (IX + ETCChannel.ornamentLoop + 0),L     ; #8265 ;  u   ; #DD,#75,#08
	LD (IX + ETCChannel.ornamentLoop + 1),H     ; #8268 ;  t   ; #DD,#74,#09
	JR ETCChannel_Tick_Link_88      ; #826B ;  5   ; #18,#35

; ix = channel
; a <- amplitude
; l <- frequency
; h <- octave
; a' <- enable (bit 0: frequency, bit 1: noise)
ETCChannel_Tick:
	LD E,(IX + ETCChannel.instrumentPitch + 0)    ; #826D ;  ^   ; #DD,#5E,#0A
	LD D,(IX + ETCChannel.instrumentPitch + 1)    ; #8270 ;  V   ; #DD,#56,#0B
	DEC (IX + ETCChannel.next_instrument)     ; #8273 ;  5   ; #DD,#35,#15
	LD L,(IX + ETCChannel.instrument + 0)     ; #8276 ;  n   ; #DD,#6E,#02
	LD H,(IX + ETCChannel.instrument + 1)     ; #8279 ;  f   ; #DD,#66,#03
	JR NZ,ETCChannel_Tick_Link_91   ; #827C ;      ; #20,#13
	LD C,#01        ; #827E ;      ; #0E,#01
ETCChannel_Tick_Link_83:
	LD A,(HL)       ; #8280 ; ~    ; #7E
	INC HL          ; #8281 ; #    ; #23
	RRCA            ; #8282 ;      ; #0F
	JR NC,ETCChannel_Tick_Instrument   ; #8283 ; 0    ; #30,#B0
	LD (IX + ETCChannel.next_instrument),C    ; #8285 ;  q   ; #DD,#71,#15
	LD (IX + ETCChannel.instrumentPitch + 1),A    ; #8288 ;  w   ; #DD,#77,#0B
	LD E,(HL)       ; #828B ; ^    ; #5E
	LD D,A          ; #828C ; W    ; #57
	LD (IX + ETCChannel.instrumentPitch + 0),E    ; #828D ;  s   ; #DD,#73,#0A
	INC HL          ; #8290 ; #    ; #23
ETCChannel_Tick_Link_91:
	PUSH HL         ; #8291 ;      ; #E5
	LD A,(IX + ETCChannel.ornamentNote)    ; #8292 ;  ~   ; #DD,#7E,#0D
	DEC (IX + ETCChannel.next_ornament)     ; #8295 ;  5   ; #DD,#35,#14
	JR NZ,ETCChannel_Tick_Link_93   ; #8298 ;      ; #20,#1A
	LD C,#01        ; #829A ;      ; #0E,#01
	LD L,(IX + ETCChannel.ornament + 0)     ; #829C ;  n   ; #DD,#6E,#06
	LD H,(IX + ETCChannel.ornament + 1)     ; #829F ;  f   ; #DD,#66,#07
ETCChannel_Tick_Link_88:
	LD A,(HL)       ; #82A2 ; ~    ; #7E
	INC HL          ; #82A3 ; #    ; #23
	CP #60          ; #82A4 ;  `   ; #FE,#60
	JR NC,ETCChannel_Tick_Ornament   ; #82A6 ; 0    ; #30,#AA
	LD (IX + ETCChannel.next_ornament),C    ; #82A8 ;  q   ; #DD,#71,#14
	LD (IX + ETCChannel.ornamentNote),A    ; #82AB ;  w   ; #DD,#77,#0D
	LD (IX + ETCChannel.ornament + 0),L     ; #82AE ;  u   ; #DD,#75,#06
	LD (IX + ETCChannel.ornament + 1),H     ; #82B1 ;  t   ; #DD,#74,#07
ETCChannel_Tick_Link_93:
	ADD A,(IX + ETCChannel.note)   ; #82B4 ;      ; #DD,#86,#0E
	CP #5F          ; #82B7 ;  _   ; #FE,#5F
	LD HL,#07FF     ; #82B9 ; !    ; #21,#FF,#07
	JR Z,ETCChannel_Tick_Link_95    ; #82BC ; (    ; #28,#16
	ADD A,#00       ; #82BE ;      ; #C6,#00
ETCChannel_Tick_patternHeight: equ $ - 1
	JR NC,ETCChannel_Tick_Link_96   ; #82C0 ; 0    ; #30,#02
	SUB #60         ; #82C2 ;  `   ; #D6,#60
ETCChannel_Tick_Link_96:
	LD HL,#FF0C     ; #82C4 ; !    ; #21,#0C,#FF
	LD B,H          ; #82C7 ; D    ; #44
ETCChannel_Tick_Link_97:
	INC H           ; #82C8 ; $    ; #24
	SUB L           ; #82C9 ;      ; #95
	JR NC,ETCChannel_Tick_Link_97   ; #82CA ; 0    ; #30,#FC
	LD C,A          ; #82CC ; O    ; #4F
	LD A,H          ; #82CD ; |    ; #7C
	LD HL,ETCChannel_noteFrequency + 12   ; #82CE ; !,   ; #21,#2C,#81
	ADD HL,BC       ; #82D1 ;      ; #09
	LD L,(HL)       ; #82D2 ; n    ; #6E
	LD H,A          ; #82D3 ; g    ; #67
ETCChannel_Tick_Link_95:
	ADD HL,DE       ; #82D4 ;      ; #19
	LD A,H          ; #82D5 ; |    ; #7C
	AND #07         ; #82D6 ;      ; #E6,#07
	LD H,A          ; #82D8 ; g    ; #67
	LD A,D          ; #82D9 ; z    ; #7A
	RRCA            ; #82DA ;      ; #0F
	RRCA            ; #82DB ;      ; #0F
	RRCA            ; #82DC ;      ; #0F
	AND #0F         ; #82DD ;      ; #E6,#0F
	EX AF, AF'      ; #82DF ;      ; #08
	EX DE,HL        ; #82E0 ;      ; #EB
	POP HL          ; #82E1 ;      ; #E1
	LD A,(IX + ETCChannel.volume)    ; #82E2 ;  ~   ; #DD,#7E,#0C
	DEC (IX + ETCChannel.next_volume)     ; #82E5 ;  5   ; #DD,#35,#16
	JR NZ,ETCChannel_Tick_Link_98   ; #82E8 ;      ; #20,#0D
	LD A,(HL)       ; #82EA ; ~    ; #7E
	INC HL          ; #82EB ; #    ; #23
	CP #00          ; #82EC ;      ; #FE,#00
ETCChannel_Tick_link_58: equ $ - 1
	JR NZ,ETCChannel_Tick_Link_99   ; #82EE ;  5   ; #20,#35
	LD C,(HL)       ; #82F0 ; N    ; #4E
	INC HL          ; #82F1 ; #    ; #23
ETCChannel_Tick_Link_105:
	LD A,(HL)       ; #82F2 ; ~    ; #7E
	INC HL          ; #82F3 ; #    ; #23
ETCChannel_Tick_Link_106:
	LD (IX + ETCChannel.next_volume),C    ; #82F4 ;  q   ; #DD,#71,#16
ETCChannel_Tick_Link_98:
	LD (IX + ETCChannel.instrument + 0),L     ; #82F7 ;  u   ; #DD,#75,#02
	LD (IX + ETCChannel.instrument + 1),H     ; #82FA ;  t   ; #DD,#74,#03
	LD (IX + ETCChannel.volume),A    ; #82FD ;  w   ; #DD,#77,#0C
	EX DE,HL        ; #8300 ;      ; #EB
	LD B,(IX + ETCChannel.volumeReduction)    ; #8301 ;  F   ; #DD,#46,#18
	LD C,A          ; #8304 ; O    ; #4F
	AND #0F         ; #8305 ;      ; #E6,#0F
	SUB B           ; #8307 ;      ; #90
	JR NC,ETCChannel_Tick_Link_100  ; #8308 ; 0    ; #30,#01
	XOR A           ; #830A ;      ; #AF
ETCChannel_Tick_Link_100:
	LD E,A          ; #830B ; _    ; #5F
	LD A,C          ; #830C ; y    ; #79
	AND #F0         ; #830D ;      ; #E6,#F0
	CALL SwapNibbleA     ; #830F ;  W   ; #CD,#57,#81
	SUB B           ; #8312 ;      ; #90
	JR NC,ETCChannel_Tick_Link_101  ; #8313 ; 0    ; #30,#01
	XOR A           ; #8315 ;      ; #AF
ETCChannel_Tick_Link_101:
	LD D,A          ; #8316 ; W    ; #57
	LD A,(IX + ETCChannel.instrumentInversion)    ; #8317 ;  ~   ; #DD,#7E,#17
	OR A            ; #831A ;      ; #B7
	LD A,E          ; #831B ; {    ; #7B
	JR NZ,ETCChannel_Tick_Link_102  ; #831C ;      ; #20,#02
	LD A,D          ; #831E ; z    ; #7A
	LD D,E          ; #831F ; S    ; #53
ETCChannel_Tick_Link_102:
	CALL SwapNibbleA     ; #8320 ;  W   ; #CD,#57,#81
	OR D            ; #8323 ;      ; #B2
	RET             ; #8324 ;      ; #C9

; ix = channel
ETCChannel_Tick_Link_99:
	PUSH HL         ; #8325 ;      ; #E5
	LD B,A          ; #8326 ; G    ; #47
	LD HL,#0000     ; #8327 ; !    ; #21,#00,#00
ETCChannel_Tick_link_59: equ $ - 2
ETCChannel_Tick_Link_104:
	LD A,(HL)       ; #832A ; ~    ; #7E
	OR A            ; #832B ;      ; #B7
	JR Z,ETCChannel_Tick_Link_103   ; #832C ; (    ; #28,#09
	INC HL          ; #832E ; #    ; #23
	LD C,(HL)       ; #832F ; N    ; #4E
	INC HL          ; #8330 ; #    ; #23
	CP B            ; #8331 ;      ; #B8
	JR NZ,ETCChannel_Tick_Link_104  ; #8332 ;      ; #20,#F6
	POP HL          ; #8334 ;      ; #E1
	JR ETCChannel_Tick_Link_105     ; #8335 ;      ; #18,#BB

ETCChannel_Tick_Link_103:
	POP HL          ; #8337 ;      ; #E1
	LD C,#01        ; #8338 ;      ; #0E,#01
	LD A,B          ; #833A ; x    ; #78
	JR ETCChannel_Tick_Link_106     ; #833B ;      ; #18,#B7

; Channel data
ETCPlayer_channel0:
	ETCChannel      ; #833D ;      ; #19 bytes

ETCPlayer_channel1:
	ETCChannel      ; #8356 ;      ; #19 bytes

ETCPlayer_channel2:
	ETCChannel      ; #836F ;      ; #19 bytes

ETCPlayer_channel3:
	ETCChannel      ; #8388 ;      ; #19 bytes

ETCPlayer_channel4:
	ETCChannel      ; #83A1 ;      ; #19 bytes

ETCPlayer_channel5:
	ETCChannel      ; #83BA ;      ; #19 bytes

SAARegisters: MACRO
	amplitude0:
		db #00
	amplitude1:
		db #00
	amplitude2:
		db #00
	amplitude3:
		db #00
	amplitude4:
		db #00
	amplitude5:
		db #00
		db #00, #00  ; reserved
	frequency0:
		db #00
	frequency1:
		db #00
	frequency2:
		db #00
	frequency3:
		db #00
	frequency4:
		db #00
	frequency5:
		db #00
		db #00, #00  ; reserved
	octave10:
		db #00
	octave32:
		db #00
	octave54:
		db #00
		db #00  ; reserved
	frequencyEnable:
		db #00
	noiseEnable:
		db #00
	noise10:
		db #00
		db #00  ; reserved
	envelope0:
		db #00
	envelope1:
		db #00
	_extendedNoise0:
		db #00  ; not an SAA1099 register
	_extendedNoise1:
		db #00  ; not an SAA1099 register
	size:
	ENDM

ETCPlayer_registers:
	SAARegisters    ; #83D3 ;      ; #1C bytes

ETCPlayer_Initialize:
	ld (ETCPlayer_GetReference_offset),hl ; #83EF ; "r   ; #22,#72,#81
	call ETCPlayer_GetReference    ; #83F2 ;  l   ; #CD,#6C,#81
	ld (ETCPlayer_songTable),bc ; #83F5 ;  Cb  ; #ED,#43,#62,#84
	call ETCPlayer_GetReference    ; #83F9 ;  l   ; #CD,#6C,#81
	ld (ETCPlayer_patterns),bc ; #83FC ;  Cw  ; #ED,#43,#77,#84
	call ETCPlayer_GetReference    ; #8400 ;  l   ; #CD,#6C,#81
	ld (ETCPlayer_instruments),bc ; #8403 ;  Cz  ; #ED,#43,#7A,#81
	call ETCPlayer_GetReference    ; #8407 ;  l   ; #CD,#6C,#81
	ld (ETCPlayer_ornaments),bc ; #840A ;  C   ; #ED,#43,#91,#81
	call ETCPlayer_GetReference    ; #840E ;  l   ; #CD,#6C,#81
	ld a,(bc)       ; #8411 ;      ; #0A
	inc bc          ; #8412 ;      ; #03
	ld (ETCChannel_Tick_link_58),a  ; #8413 ; 2    ; #32,#ED,#82
	ld (ETCChannel_Tick_link_59),bc ; #8416 ;  C(  ; #ED,#43,#28,#83

	; Clear channel data
	ld hl,ETCPlayer_channel0    ; #841A ; !=   ; #21,#3D,#83
	ld b,#B2        ; #841D ;      ; #06,#B2
	xor a           ; #841F ;      ; #AF
ETCPlayer_Initialize_ChannelClearLoop:
	ld (hl),a       ; #8420 ; w    ; #77
	inc hl          ; #8421 ; #    ; #23
	djnz ETCPlayer_Initialize_ChannelClearLoop   ; #8422 ;      ; #10,#FC
	inc a           ; #8424 ; <    ; #3C
	ld (ETCPlayer_Tick_link_8),a   ; #8425 ; 2    ; #32,#07,#80

	; Init channel data
	ld ix,ETCPlayer_channel0    ; #8428 ;  !=  ; #DD,#21,#3D,#83
	ld de,ETCChannel.size     ; #842C ;      ; #11,#19,#00
	ld b,6        ; #842F ;      ; #06,#06
ETCPlayer_Initialize_ChannelInitLoop:
	ld (ix + ETCChannel.next_ornament),a    ; #8431 ;  w   ; #DD,#77,#14
	ld (ix + ETCChannel.next_instrument),a    ; #8434 ;  w   ; #DD,#77,#15
	ld (ix + ETCChannel.next_volume),a    ; #8437 ;  w   ; #DD,#77,#16
	ld hl,ETCChannel_instrumentNone   ; #843A ; !,   ; #21,#2C,#81
	ld (ix + ETCChannel.instrumentStart + 0),l    ; #843D ;  u   ; #DD,#75,#0F
	ld (ix + ETCChannel.instrumentStart + 1),h    ; #8440 ;  t   ; #DD,#74,#10
	ld (ix + ETCChannel.instrument + 0),l     ; #8443 ;  u   ; #DD,#75,#02
	ld (ix + ETCChannel.instrument + 1),h     ; #8446 ;  t   ; #DD,#74,#03
	ld hl,ETCChannel_ornamentNone   ; #8449 ; !>   ; #21,#3E,#81
	ld (ix + ETCChannel.ornamentStart + 0),l    ; #844C ;  u   ; #DD,#75,#11
	ld (ix + ETCChannel.ornamentStart + 1),h    ; #844F ;  t   ; #DD,#74,#12
	add ix,de       ; #8452 ;      ; #DD,#19
	djnz ETCPlayer_Initialize_ChannelInitLoop   ; #8454 ;      ; #10,#DB

	; mute & reset
	ld de,#1C02     ; #8456 ;      ; #11,#02,#1C
	ld bc,ETCPlayer_SAA_ADDRESS_PORT     ; #8459 ;      ; #01,#FF,#01
	out (c),d       ; #845C ;  Q   ; #ED,#51
	dec ETCPlayer_SAA_MODE_REG           ; #845E ;      ; #05
	out (c),e       ; #845F ;  Y   ; #ED,#59

link_50:
	LD HL,#0000     ; #8461 ; !    ; #21,#00,#00
ETCPlayer_songTable: equ $ - 2
link_119:
	LD C,(HL)       ; #8464 ; N    ; #4E
	LD A,C          ; #8465 ; y    ; #79
	INC HL          ; #8466 ; #    ; #23
	INC A           ; #8467 ; <    ; #3C
	JR Z,ETCPlayer_Initialize_GetSongTableLoop   ; #8468 ; (:   ; #28,#3A
	INC A           ; #846A ; <    ; #3C
	JR Z,ETCPlayer_Initialize_SetSongTableLoop   ; #846B ; (<   ; #28,#3C
	SUB #62         ; #846D ;  b   ; #D6,#62
	JR NC,ETCPlayer_Initialize_SetPatternHeight  ; #846F ; 0=   ; #30,#3D
	LD (ETCPlayer_songTable),HL ; #8471 ; "b   ; #22,#62,#84
	SLA C           ; #8474 ;  !   ; #CB,#21
	LD HL,#0000     ; #8476 ; !    ; #21,#00,#00
ETCPlayer_patterns: equ $ - 2
	CALL ETCPlayer_GetReferenceAtIndex    ; #8479 ;  d   ; #CD,#64,#81
	LD (ETCPlayer_channel0.track),BC  ; #847C ;  C=  ; #ED,#43,#3D,#83
	CALL ETCPlayer_GetReference    ; #8480 ;  l   ; #CD,#6C,#81
	LD (ETCPlayer_channel1.track),BC ; #8483 ;  CV  ; #ED,#43,#56,#83
	CALL ETCPlayer_GetReference    ; #8487 ;  l   ; #CD,#6C,#81
	LD (ETCPlayer_channel2.track),BC ; #848A ;  Co  ; #ED,#43,#6F,#83
	CALL ETCPlayer_GetReference    ; #848E ;  l   ; #CD,#6C,#81
	LD (ETCPlayer_channel3.track),BC ; #8491 ;  C   ; #ED,#43,#88,#83
	CALL ETCPlayer_GetReference    ; #8495 ;  l   ; #CD,#6C,#81
	LD (ETCPlayer_channel4.track),BC ; #8498 ;  C   ; #ED,#43,#A1,#83
	CALL ETCPlayer_GetReference    ; #849C ;  l   ; #CD,#6C,#81
	LD (ETCPlayer_channel5.track),BC ; #849F ;  C   ; #ED,#43,#BA,#83
	RET             ; #84A3 ;      ; #C9

ETCPlayer_Initialize_GetSongTableLoop:
	LD HL,#0000     ; #84A4 ; !    ; #21,#00,#00
ETCPlayer_Initialize_songTableLoop: equ $ - 2
	JR link_119     ; #84A7 ;      ; #18,#BB

ETCPlayer_Initialize_SetSongTableLoop:
	LD (ETCPlayer_Initialize_songTableLoop),HL ; #84A9 ; "    ; #22,#A5,#84
	JR link_119     ; #84AC ;      ; #18,#B6

ETCPlayer_Initialize_SetPatternHeight:
	LD (ETCChannel_Tick_patternHeight),A  ; #84AE ; 2    ; #32,#BF,#82
	JR link_119     ; #84B1 ;      ; #18,#B1

ETCPlayer_soundData:
