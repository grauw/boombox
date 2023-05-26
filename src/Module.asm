;
; An Etracker module
;
Module: MACRO ?data, ?autoPlayPattern = 0FFH
	data:
		dw ?data
	autoPlayPattern:
		db ?autoPlayPattern
	_size:
	ENDM

Module_playlist:
	Module Module_highColor_data
	Module Module_seventh_data
	Module Module_electron_data
	Module Module_electro1_data
	Module Module_electro3_data
	Module Module_hubbardsChoice_data
	Module Module_asSidAsItGets_data
	Module Module_robLike1_data
	Module Module_harlequinTitle_data, 0x20
