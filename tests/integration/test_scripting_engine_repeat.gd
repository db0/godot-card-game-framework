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

func test_repeat():
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 3,
			"repeat": 3,
			"counter_name":  "research"}]}}
	card.execute_scripts()
	assert_eq(9,board.counters.get_counter("research"),
			"Counter increased by specified amount")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 2,
			"repeat": 3,
			"set_to_mod": true,
			"counter_name": "credits"}]}}
	card.execute_scripts()
	assert_eq(2,board.counters.get_counter("credits"),
			"Counter set to the specified amount")

func test_repeat_with_target():
	card.scripts = {"manual": {"hand": [
			{"name": "mod_tokens",
			"subject": "target",
			"modification": 2,
			"repeat": 3,
			"token_name":  "industry"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	# My scripts are slower now
	yield(yield_for(0.2), YIELD)
	var industry_token: Token = target.tokens.get_token("industry")
	assert_eq(6,industry_token.count,"Token set to specified amount")
