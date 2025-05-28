extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = await confirm_return.completed
	cards = draw_test_cards(5)
	await yield_for(0.1).YIELD
