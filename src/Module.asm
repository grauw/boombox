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
	Module Module_vexxIngame_data
	Module Module_highColor_data
	Module Module_seventh_data
	Module Module_electron_data
	Module Module_electro1_data
	Module Module_electro3_data
	Module Module_hubbardsChoice_data
	Module Module_harlequinTitle_data, 0x20
	Module Module_robLike1_data

	SECTION page2

Module_vexxIngame_data:
	INCBIN "vexxingame.lz4"
Module_highColor_data:
	INCBIN "highcolor.lz4"
Module_seventh_data:
	INCBIN "seventh.lz4"
Module_electron_data:
	INCBIN "electron.lz4"
Module_electro1_data:
	INCBIN "electro1.lz4"
Module_electro3_data:
	INCBIN "electro3.lz4"

	ENDS

	SECTION page1

Module_hubbardsChoice_data:
	INCBIN "hubbardschoice.lz4"
Module_harlequinTitle_data:
	INCBIN "harlequintitle.lz4"
Module_robLike1_data:
	INCBIN "roblike1.lz4"

	ENDS
