extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
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
	yield(yield_for(0.1), YIELD)
	if scripting_engine is GDScriptFunctionState: # Still seeking...
		yield(card.targeting_arrow, "initiated_targeting")
	#watch_signals(scripting_engine)
	yield(target_card(card,card), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 270,
			"First rotation should happen before targetting second time")
	yield(target_card(card,card), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 90,
			"Second rotation should also happen")
# Cannot figure out how to catch this signal...
#	assert_signal_emitted(scripting_engine,"tasks_completed",
#			"Scripts finished signal fires")

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
			"filter_properties_seek": {"Type": ttype},
			"degrees": 180},
			{"name": "rotate_card",
			"subject": "boardseek",
			"subject_count": "all",
			"filter_properties_seek": {"Type": ttype2},
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
			{"name": "move_card_cont_to_board",
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
	yield(yield_for(1), YIELD)
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
			"filter_properties_seek": {"Tags": "Tag 1"},
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
			{"name": "move_card_cont_to_board",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"filter_properties_tutor": {"Type": "Red"},
			"board_position":  Vector2(1000,200)}]}}
	card.execute_scripts()
	target = cfc.NMAP.board.get_card(0)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq("Red",target.properties["Type"],
			"Card of the correct type should be placed on the board")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_board",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"filter_properties_tutor": {"Name": "Multiple Choices Test Card"},
			"board_position":  Vector2(100,200)}]}}
	card.execute_scripts()
	target = cfc.NMAP.board.get_card(1)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq("Multiple Choices Test Card",target.card_name,
			"Card of the correct name should be placed on the board")

func test_subject_index():
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_board",
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
			{"name": "move_card_cont_to_board",
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
