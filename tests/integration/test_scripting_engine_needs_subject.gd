extends "res://tests/UTcommon.gd"

class TestNeedSubjectWithPrevious:
	extends "res://tests/ScEng_common.gd"

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
		await move_mouse(Vector2(0,0), "fast")
		unclick_card_anywhere(card)
		await yield_to(card._flip_tween, "finished", 0.5).YIELD
		await yield_to(card._flip_tween, "finished", 0.5).YIELD
		assert_true(card.is_faceup,
				"Target should be face-up because target not found")
		card.execute_scripts()
		await target_card(card,target)
		await yield_to(target._flip_tween, "finished", 0.5).YIELD
		await yield_to(target._flip_tween, "finished", 0.5).YIELD
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
		await target_card(card,target)
		await yield_to(target._flip_tween, "finished", 0.5).YIELD
		await yield_to(target._flip_tween, "finished", 0.5).YIELD
		assert_true(target.is_faceup,
				"Target should be left face-up because is_cost overrides needs_subject")
