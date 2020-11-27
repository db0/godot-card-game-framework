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
	target = cards[2]


func test_basics():
	card.scripts = {"hand": [
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 270}]}
	watch_signals(card.scripting_engine) 
	card._execute_scripts()
	assert_eq(card.scripting_engine._card_owner, card,
			"Scripting Engine owner card is self")
	assert_false(card.scripting_engine._common_target, 
			"_common_target should start false unless defined")
	assert_signal_emitted(card.scripting_engine,"scripts_completed")
	yield(drag_drop(card, Vector2(100,200)), "completed")
	card._execute_scripts()
	assert_eq(target.card_rotation, 0, 
			"Script should not work from a different state")
	assert_signal_emitted(card.scripting_engine,"scripts_completed")

	# The below tests _common_target == false
	card.scripts = {"board": [
			{"name": "rotate_card", 
			"subject": "target",
			"common_target_request": false, 
			"degrees": 270},
			{"name": "rotate_card",
			"subject": "target",
			"common_target_request": false, 
			"degrees": 90}]}
	card._execute_scripts()
	yield(target_card(card,card), "completed")
	yield(yield_to(card.get_node("Tween"), "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 270, 
			"First rotation should happen before targetting second time")
	yield(target_card(card,card), "completed")
	yield(yield_to(card.get_node("Tween"), "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 90, 
			"Second rotation should also happen")
	card.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	card.scripts = {"hand": [{"name": "flip_card","set_faceup": true}]}
	card._execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(card.is_faceup, 
			"Scripts should not fire while card is face-down")


# Checks that scripts from the CardScripts have been loaded correctly
func test_CardScripts():
	card = cards[0]
	target = cards[2]
	yield(drag_drop(target, Vector2(800,200)), "completed")
	yield(drag_drop(card, Vector2(100,200)), "completed")
	card._execute_scripts()
	yield(target_card(card,target,"slow"), "completed")
	yield(yield_to(target.get_node("Tween"), "tween_all_completed", 1), YIELD)
	# This also tests the _common_target set
	assert_false(target.is_faceup, 
			"Test1 script leaves target facedown")
	assert_eq(target.card_rotation, 180, 
			"Test1 script rotates 180 degrees")

# Checks that custom scripts fire correctly
func test_custom_script():
	card = cards[1]
	# Custom scripts have to be predefined in code
	# So not possible to specify them as runtime scripts
	card._execute_scripts()
	yield(yield_for(0.1), YIELD)
	assert_freed(card, "Test Card 2")
	card = cards[0]
	target = cards[2]
	card._execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_for(0.1), YIELD)
	assert_freed(target, "Test Card 1")


func test_rotate_card():
	card.scripts = {"board": [
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 90}]}
	yield(drag_drop(card, Vector2(100,200)), "completed")
	card._execute_scripts()
	yield(yield_to(card.get_node("Tween"), "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 90, 
			"Card should be rotated 90 degrees")


func test_flip_card():
	card.scripts = {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false}]}
	card._execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(target.is_faceup, 
			"Target should be face-down")
	card.scripts = {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": true}]}
	card._execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(target.is_faceup, 
			"Target should be face-up again")


func test_move_card_to_container():
	card.scripts = {"hand": [
			{"name": "move_card_to_container",
			"subject": "self",
			"container":  cfc.NMAP.discard}]}
	card._execute_scripts()
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.discard,card.get_parent(),
			"Card should have moved to different container")


func test_move_card_to_board():
	card.scripts = {"hand": [
			{"name": "move_card_to_board",
			"subject": "self",
			"vector2":  Vector2(100,100)}]}
	card._execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.board,card.get_parent(),
			"Card should have moved to board")
	assert_eq(Vector2(100,100),card.global_position,
			"Card should have moved to specified position")

