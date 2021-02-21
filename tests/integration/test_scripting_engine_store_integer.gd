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


func test_store_integer_inverted():
	board.counters.mod_counter("research", 3)
	card.scripts = {"manual": {
			"hand": [
				{
					"name": "mod_counter",
					"modification": 0,
					"set_to_mod": true,
					"counter_name":  "research",
					"store_integer": true
					# Should store a diffference of -3
				},
				{
					"name": "move_card_to_container",
					"src_container": cfc.NMAP.deck,
					"dest_container": cfc.NMAP.discard,
					"subject": "index",
					"subject_count": "retrieve_integer",
					"is_inverted": true,
					"subject_index": "top"
				}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(discard.get_card_count(),3, "3 cards should have been discarded")

func test_store_integer_with_counters():
	board.counters.mod_counter("research", 3)
	board.counters.mod_counter("credits", 5, true)
	card.scripts = {"manual": {
			"hand": [
				{
					"name": "mod_counter",
					"modification": 5,
					"set_to_mod": true,
					"counter_name":  "research",
					"store_integer": true
					# Should store a difference of +2
				},
				{
					"name": "mod_counter",
					"counter_name": "credits",
					"modification": "retrieve_integer",
				}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(board.counters.get_counter("credits"),7, 
		"3 Credits removed")

func test_store_integer_with_tokens():
	yield(table_move(cards[1], Vector2(800,200)), "completed")
	yield(table_move(cards[2], Vector2(100,200)), "completed")
	cards[1].tokens.mod_token("void",7)
	cards[2].tokens.mod_token("void",1)
	# Set all cards on the board to 2 void tokens.
	# Mill a card for each extra token that exists on the board
	# at the end of this operation.
	card.scripts = {"manual": {"hand": [
			{
				"name": "mod_tokens",
				"subject": "boardseek",
				"subject_count": "all",
				"token_name": "void",
				"store_integer": true,
				"modification": 5,
				"set_to_mod": true},
				# The cumulative difference of tokens at the end
				# is going to be +2 (5-1 + 5-7)
			{
				"name": "move_card_to_container",
				"src_container": cfc.NMAP.deck,
				"dest_container": cfc.NMAP.discard,
				"subject": "index",
				"subject_count": "retrieve_integer",
				"subject_index": "top"
			}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(discard.get_card_count(),2, "2 cards should have been discarded")

