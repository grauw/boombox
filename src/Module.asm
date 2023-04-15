;
; An Etracker module
;
Module: MACRO ?data, ?name
	data:
		dw ?data
	name:
		dw ?name
	_size:
	ENDM

Module_playlist:
	Module Module_electro1_data, Module_electro1_name
	Module Module_electro3_data, Module_electro3_name
	Module Module_electron_data, Module_electron_name
	Module Module_highColor_data, Module_highColor_name
	Module Module_seventh_data, Module_seventh_name
	Module Module_vexxIngame_data, Module_vexxIngame_name

Module_electro1_name:
	db "ELECTRO-1",0
Module_electro3_name:
	db "ELECTRO-3",0
Module_electron_name:
	db "ELECTRON",0
Module_highColor_name:
	db "HIGH COLOR",0
Module_seventh_name:
	db "SEVENTH",0
Module_vexxIngame_name:
	db "VEXX INGAME",0

	SECTION page2

Module_electro1_data:
	INCBIN "electro1.lz4"
Module_electro3_data:
	INCBIN "electro3.lz4"
Module_electron_data:
	INCBIN "electron.lz4"
Module_highColor_data:
	INCBIN "highcolor.lz4"
Module_seventh_data:
	INCBIN "seventh.lz4"
Module_vexxIngame_data:
	INCBIN "vexxingame.lz4"

	ENDS
