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


func test_basics():
	card.scripts = {"manual": { "hand": [
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 270}]}}
	yield(table_move(card, Vector2(100,200)), "completed")
	card.execute_scripts()
	assert_eq(target.card_rotation, 0,
			"Script should not work from a different state")
	yield(yield_for(0.5), YIELD)
	# The below tests _common_target == false
	card.scripts = {"hand": [{}]}
	card.execute_scripts()
	pending("Empty does not create a ScriptingEngine object")
	card.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	card.scripts = {"hand": [{"name": "flip_card","set_faceup": true}]}
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
			"Scripts should not fire while card is face-down")
	card.scripts = {"hand": [{}]}

func test_state_executions():
	card.scripts = {"manual": {"hand": [
			{"name": "flip_card",
			"subject": "self",
			"set_faceup": false}]}}
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
		"Target should be face-down")
	card.is_faceup = true
	card.state = Card.CardState.PUSHED_ASIDE
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
		"Target should be face-down")
	card.is_faceup = true
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	card.state = Card.CardState.FOCUSED_IN_HAND
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
		"Target should be face-down")
	card.is_faceup = true
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	card.scripts = {"manual": {"board": [
			{"name": "flip_card",
			"subject": "self",
			"set_faceup": false}]}}
	yield(table_move(card, Vector2(500,100)), "completed")
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
		"Target should be face-down")
	card.is_faceup = true
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	card.state = Card.CardState.FOCUSED_ON_BOARD
	card.execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup,
		"Target should be face-down")
	card.move_to(cfc.NMAP.discard)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	card.scripts = {"manual": {"pile": [
			{"name": "move_card_to_board",
			"subject": "self",
			"board_position":  Vector2(100,100)}]}}
	discard._on_View_Button_pressed()
	yield(yield_for(1), YIELD)
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(Vector2(100,100),card.global_position,
			"Card should have moved to specified position")
	card.move_to(cfc.NMAP.discard)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	card.state = Card.CardState.FOCUSED_IN_POPUP
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(Vector2(100,100),card.global_position,
			"Card should have moved to specified position")


func test_subject_target():
	yield(table_move(card, Vector2(100,200)), "completed")
	card.scripts = {"manual": {"board": [
			{"name": "rotate_card",
			"subject": "target",
			"degrees": 270},
			{"name": "rotate_card",
			"subject": "target",
			"degrees": 90}
			]}}
	var scripting_engine = card.execute_scripts()
	if scripting_engine is GDScriptFunctionState: # Still seeking...
		yield(yield_to(card.targeting_arrow, "initiated_targeting", 0.2), YIELD)
	#watch_signals(scripting_engine)
	yield(yield_to(target_card(card,card), "completed", 0.1), YIELD)
#	yield(target_card(card,card), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 0.4), YIELD)
	assert_eq(card.card_rotation, 270,
			"First rotation should happen before targetting second time")
	yield(yield_to(target_card(card,card), "completed", 0.1), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.4), YIELD)
	assert_eq(card.card_rotation, 90,
			"Second rotation should also happen")


func test_subject_boardseek():
	var target2: Card = cards[2]
	var ttype : String = target.properties["Type"]
	var ttype2 : String = target2.properties["Type"]
	yield(table_move(target, Vector2(500,200)), "completed")
	yield(table_move(cards[2], Vector2(800,200)), "completed")
	card.scripts = {"manual": {"hand": [
			{"name": "rotate_card",
			"subject": "boardseek",
			"subject_count": "all",
			"filter_state_seek": [{"filter_properties":  {"Type": ttype}}],
			"degrees": 180},
			{"name": "rotate_card",
			"subject": "boardseek",
			"subject_count": "all",
			"filter_state_seek": [{"filter_properties": {"Type": ttype2}}],
			"degrees": 90}]}}
	var scripting_engine = card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_eq(target.card_rotation, 180,
			"Card on board matching property should be rotated 90 degrees")
	assert_eq(target2.card_rotation, 90,
			"Card on board matching property should be rotated 180 degrees")


func test_subject_previous():
	target = cfc.NMAP.deck.get_card(1)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_index": 1,
			"src_container":  cfc.NMAP.deck,
			"board_position":  Vector2(1000,200)},
			{"name": "flip_card",
			"subject": "previous",
			"set_faceup": true},
			{"name": "rotate_card",
			"subject": "previous",
			"degrees": 90}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(target.card_rotation, 90,
			"Target should be pre-selected to be rotated")
	assert_true(target.is_faceup,
			"Target should be pre-selected to be flipped")


func test_subject_boardseek_previous():
	var target2: Card = cards[2]
	var ttype : String = target.properties["Type"]
	yield(table_move(target, Vector2(500,200)), "completed")
	yield(table_move(cards[2], Vector2(800,200)), "completed")
	card.scripts = {"manual": {"hand": [
			{"name": "rotate_card",
			"subject": "boardseek",
			"subject_count": "all",
			"filter_state_seek": [{"filter_properties": {"Tags": "Tag 1"}}],
			"degrees": 90},
			{"name": "flip_card",
			"subject": "previous",
			"set_faceup": false}]}}
	var scripting_engine = card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_false(target.is_faceup,
			"Target should be pre-selected to be flipped")
	assert_false(target2.is_faceup,
			"Target2 should be pre-selected to be flipped")


func test_subject_tutor():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"filter_state_tutor": [{"filter_properties": {"Type": "Red"}}],
			"board_position":  Vector2(1000,200)}]}}
	card.execute_scripts()
	target = cfc.NMAP.board.get_card(0)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq("Red",target.properties["Type"],
			"Card of the correct type should be placed on the board")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"filter_state_tutor": [{"filter_properties":
				{"Name": "Multiple Choices Test Card"}}],
			"board_position":  Vector2(100,200)}]}}
	card.execute_scripts()
	target = cfc.NMAP.board.get_card(1)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq("Multiple Choices Test Card",target.card_name,
			"Card of the correct name should be placed on the board")

func test_subject_index():
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_index": 5,
			"src_container":  cfc.NMAP.deck,
			"board_position":  Vector2(1000,200)}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.board,target.get_parent(),
			"Card should have moved to board")
	target = cfc.NMAP.deck.get_card(0)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"src_container":  cfc.NMAP.deck,
			"board_position":  Vector2(100,200)}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.board,target.get_parent(),
			"When index is not specified, top card should have moved to the board")

# Checks that scripts from the CardScriptDefinitions.gd have been loaded correctly
func test_CardScripts():
	card = cards[1]
	target = cards[3]
	yield(table_move(target, Vector2(800,200)), "completed")
	yield(table_move(card, Vector2(100,200)), "completed")
	card.execute_scripts()
	yield(target_card(card,target,"slow"), "completed")
	yield(yield_to(target.get_node("Tween"), "tween_all_completed", 1), YIELD)
	# This also tests the _common_target set
	assert_false(target.is_faceup,
			"Test1 script leaves target facedown")
	assert_eq(target.card_rotation, 180,
			"Test1 script rotates 180 degrees")
	yield(table_move(cards[4], Vector2(500,200)), "completed")
	card.execute_scripts()
	yield(target_card(card,cards[4]), "completed")
	yield(yield_to(cards[4].get_node("Tween"), "tween_all_completed", 1), YIELD)
	assert_false(cards[4].is_faceup,
			"Ensure targeting is cleared after first ScriptingEngine")


func test_target_script_on_drag_from_hand():
	cfc.NMAP.board.counters.mod_counter("credits", 10, true)
	card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": -2,
				"is_cost": true,
				"counter_name": "credits"},
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false}]}}
	card.hand_drag_starts_targeting = true
	yield(drag_card(card, Vector2(300,300)), 'completed')
	assert_true(card.get_node("TargetLine/ArrowHead").visible,
			"Targeting has started on long-click")
	yield(target_card(card,target), "completed")
	assert_eq(board.counters.get_counter("credits"),8,
			"Counter reduced by 2")
	assert_false(target.is_faceup,
			"Target is face-down")
	card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": -10,
				"is_cost": true,
				"counter_name": "credits"},
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false}]}}
	target = cards[2]
	yield(drag_card(card, Vector2(300,300)), 'completed')
	assert_false(card.get_node("TargetLine/ArrowHead").visible,
			"Targeting not started because costs cannot be paid")
	yield(target_card(card,target), "completed")
	assert_eq(board.counters.get_counter("credits"),8,
			"Counter not reduced")
	assert_true(target.is_faceup,
			"Target stayed face-up since cost could not be paid")
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"is_cost": true,
				"set_faceup": false},
				{"name": "mod_counter",
				"modification": -10,
				"is_cost": true,
				"counter_name": "credits"}]}}
	yield(drag_card(card, Vector2(300,300)), 'completed')
	assert_true(card.get_node("TargetLine/ArrowHead").visible,
			"Targeting started because targeting is_cost")
	yield(target_card(card,target), "completed")
	assert_eq(board.counters.get_counter("credits"),8,
			"Counter not reduced")
	assert_true(target.is_faceup,
			"Target stayed face-up since cost could not be paid")
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"is_cost": true,
				"set_faceup": false},
				{"name": "mod_counter",
				"modification": -3,
				"counter_name": "credits"}]}}
	yield(drag_card(card, Vector2(300,300)), 'completed')
	unclick_card_anywhere(card)
	assert_eq(board.counters.get_counter("credits"),8,
			"Counter not reduced since nothing was targeted")
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false},
				{"name": "mod_counter",
				"modification": -3,
				"is_cost": true,
				"counter_name": "credits"}]}}
	yield(drag_card(card, Vector2(300,300)), 'completed')
	unclick_card_anywhere(card)
	assert_eq(board.counters.get_counter("credits"),5,
			"Counter reduced since targeting was not a cost")


func test_subject_previous_with_filters():
	target = cfc.NMAP.deck.get_card(1)
	# Discard a Blue card to get 1 research.
	# Discard a Green card to get 2 research.
	card.scripts = {"manual": {
				"hand":[
					{
						"name": "move_card_to_container",
						SP.KEY_DEST_CONTAINER: cfc.NMAP.discard,
						"subject": "target",
						"is_cost": true,
						"filter_state_subject": [
							{"filter_properties1": {"Type": "Blue"}},
							{"filter_properties1": {"Type": "Red"}},
						],
					},
					{
						"name": "mod_counter",
						"counter_name": "research",
						"modification": 1,
						"subject": "previous",
						"filter_state_subject": [
							{"filter_properties": {"Type": "Blue"}},
						],
					},
					{
						"name": "mod_counter",
						"counter_name": "research",
						"modification": 2,
						"subject": "previous",
						"filter_state_subject": [{
							"filter_properties": {"Type": "Red"},
						}],
					},
				],
			},
		}
	card._debugger_hook = true
	yield(execute_with_target(card,cards[2]), "completed")
	assert_eq(board.counters.get_counter("research"),2,
			"Counter increased by specified amount")
	yield(execute_with_target(card,cards[4]), "completed")
	assert_eq(board.counters.get_counter("research"),3,
			"Counter increased by specified amount")

# Tests that a card subject can grab from the next
# As long as the targeting is_cost
func test_subject_next():
	card.scripts = {
			"manual": {
				"hand":[
					# This has to go before the move, or the check for
					# the parent will happen after the card is already
					# in the discard pile
					{
						"name": "mod_counter",
						"counter_name": "research",
						"modification": 3,
						"subject": "previous",
						"filter_state_subject": [
							{"filter_parent": cfc.NMAP.hand},
						],
					},
					{
						"name": "move_card_to_container",
						"dest_container": cfc.NMAP.discard,
						"subject": "target",
						"is_cost": true,
					},
				],
			},
		}
	yield(execute_with_target(card,target), "completed")
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(board.counters.get_counter("research"),3,
			"Counter set to the specified amount")

