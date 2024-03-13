extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	await setup_board()
	cards = draw_test_cards(5)
	await yield_for(0.1)
