extends "res://tests/Basic_common.gd"

func before_each():
	super.before_each()
	board.get_node("EnableAttach").button_pressed = true
	await yield_for(0.1).YIELD
