;
; An Etracker module
;
Module: MACRO ?data
	data:
		dw ?data
	_size:
	ENDM

Module_playlist:
	Module Module_vexxIngame_data
	Module Module_highColor_data
	Module Module_seventh_data
	Module Module_electron_data
	Module Module_electro1_data
	Module Module_electro3_data

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
