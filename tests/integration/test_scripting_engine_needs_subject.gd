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

func test_need_subject_with_previous():
	card.scripts = {"manual": {"hand": [
			{
				"name": "mod_tokens",
				"subject": "target",
				"modification": -5,
				"token_name":  "industry",
				"needs_subject": true,
			},
			{
				"name": "flip_card",
				"subject": "previous",
				"set_faceup": false
			},
			]}}
	card.execute_scripts()
	yield(move_mouse(Vector2(0,0), "fast"), "completed")
	unclick_card_anywhere(card)
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(card.is_faceup,
			"Target should be face-up because target not found")
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(target.is_faceup,
			"Target should be face-down because needs_target worked")
			
func test_need_subject_with_cost():
	card.scripts = {"manual": {"hand": [
			{
				"name": "mod_tokens",
				"subject": "target",
				"modification": -5,
				"token_name":  "industry",
				"needs_subject": true,
				"is_cost": true,
			},
			{
				"name": "flip_card",
				"subject": "previous",
				"set_faceup": false
			},
			]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(target.is_faceup,
			"Target should be left face-up because is_cost overrides needs_subject")
