extends "res://tests/Basic_common.gd"

func before_each():
	.before_each()
	board.get_node("EnableAttach").pressed = true
	yield(yield_for(0.1), YIELD)
