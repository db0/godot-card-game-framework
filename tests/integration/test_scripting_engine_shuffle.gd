extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(0.1), YIELD)
	card = cards[0]
	target = cards[2]

func test_shuffle():
	card.scripts = {"manual": {"hand": [
			{"name": "shuffle_container",
			"dest_container": deck,},
			{"name": "mod_counter",
			"modification": 2,
			"counter_name": "research"}]}}
	card.execute_scripts()
	yield(yield_to(deck, "shuffle_completed", 1.5), YIELD)
	assert_eq(2,board.counters.get_counter("research"),
			"Counter increased by specified amount")
