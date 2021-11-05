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
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[1]

func test_fail_cost_on_skip_false():
	# Gain 5 credits and 5 research if research >= 3
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 5,
			"is_cost": true,
			"filter_per_counter": {
				"counter_name": "research",
				"filter_count": 3,
			},
			"counter_name":  "credits"},
			{"name": "mod_counter",
			"modification": 5,
			"counter_name":  "research"}
			]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("credits"),100,
			"Counter set to the specified amount")
	assert_eq(board.counters.get_counter("research"),5,
			"Counter set to the specified amount")

func test_fail_cost_on_skip_true():
	# Gain 5 credits if research >= 3. Gain 5 research. 
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 5,
			"is_cost": true,
			"fail_cost_on_skip": true,
			"filter_per_counter": {
				"counter_name": "research",
				"filter_count": 3,
			},
			"counter_name":  "credits"},
			{"name": "mod_counter",
			"modification": 5,
			"counter_name":  "research"}
			]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("credits"),100,
			"Counter set to the specified amount")
	assert_eq(board.counters.get_counter("research"),0,
			"Counter not modified because filter skipped")
