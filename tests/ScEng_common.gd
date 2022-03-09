extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card
var initial_card_count := 5
var card_index := 0
var target_index := 2
var initial_wait := 0.1

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(initial_card_count)
	yield(yield_for(initial_wait), YIELD)
	card = cards[card_index]
	target = cards[target_index]
