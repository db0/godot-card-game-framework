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


func test_else():
	card.scripts = {"manual": {"board": [
			{"name": "rotate_card",
			"subject": "self",
			"is_cost": true,
			"degrees": 90},
			{"name": "mod_counter",
			"modification": 1,
			"counter_name":  "research"},
			{"name": "mod_counter",
			"modification": -10,
			"counter_name":  "credits"},]}}
	yield(table_move(card, Vector2(100,200)), "completed")
	card.execute_scripts()
	assert_eq(1,board.counters.get_counter("research"),
			"Counter increased because rotation cost could be paid")
	card.execute_scripts()
	assert_eq(90,board.counters.get_counter("credits"),
			"Counter decreased because rotation cost could be paid")

