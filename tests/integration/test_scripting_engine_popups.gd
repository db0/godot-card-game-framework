extends "res://tests/UTcommon.gd"

class TestFilteredMultipleChoice:
	extends "res://tests/ScEng_common.gd"

	func test_filtered_multiple_choice():
		card.scripts = {"card_flipped": {
					"trigger": "another",
					"filter_state_trigger": [{"filter_properties": {"Type": "Red"}}],
					"board": {
						"Rotate This Card": [
							{
								"name": "rotate_card",
								"subject": "self",
								"degrees": 90,
							}
						],
						"Flip This Card Face-down": [
							{
								"name": "flip_card",
								"subject": "self",
								"set_faceup": false,
							}
						]
					},
				},
		}
		await table_move(card, Vector2(100,200))
		target.is_faceup = false
		await yield_for(0.1)
		var menu = board.get_node("CardChoices")
		assert_true(menu.visible)
		menu._on_CardChoices_id_pressed(3)
		assert_eq("Rotate This Card",menu.selected_key)
		await yield_for(0.1)
		menu.hide()
		assert_eq(card.card_rotation, 90,
				"Card should be rotated 90 degrees")
		await yield_for(0.1)
		cards[3].is_faceup = false
		await yield_for(0.1)
		menu = board.get_node("CardChoices")
		assert_null(menu, "menu should not appear when filter does not match")
	#
	func test_task_confirm_dialog() -> void:
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "self",
					"is_optional_task": true,
					"set_faceup": false}]}}
		card.execute_scripts()
		var confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			assert_true(confirm.visible)
			confirm._on_OptionalConfirmation_confirmed()
			assert_true(confirm.is_accepted, "Confirmation dialog accepted")
			confirm.hide()
		await yield_to(card._flip_tween, "finished", 0.5)
		assert_false(card.is_faceup,
				"Card should be face-down after accepted dialog")

		target.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "target",
				"is_optional_task": true,
				"dest_container": "discard"},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		target.execute_scripts()
		assert_true(target.is_faceup,
				"Card should not be face-down until after accepted dialog")
		confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			confirm._on_OptionalConfirmation_cancelled()
			assert_false(confirm.is_accepted, "Confirmation dialog not accepted")
			confirm.hide()
		if target._flip_tween:
			await yield_to(target._flip_tween, "finished", 0.5)
		assert_false(target.is_faceup,
				"Card should be face-down after even afer other optional task canceled")
		assert_false(target.targeting_arrow.is_targeting,
				"Card did not start targeting since dialogue canceled")

class TestTaskConfimDialogueTarget:
	extends "res://tests/ScEng_common.gd"

	func test_task_confirm_cost_dialog_cancelled_target() -> void:
		var confirm
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"is_optional_task": true,
				"is_cost": true,
				"subject": "self",
				"set_faceup": false},
				{"name": "move_card_to_container",
				"subject": "target",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			confirm._on_OptionalConfirmation_cancelled()
			confirm.hide()
		await yield_to(card._flip_tween, "finished", 0.5)
		assert_true(card.is_faceup,
				"Card should not be face-down with a canceled cost dialog")
		assert_false(card.targeting_arrow.is_targeting,
				"Card should not start targeting once cost dialogue canceled")


	func test_task_confirm_cost_dialogue_accepted_target() -> void:
		var confirm
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"is_optional_task": true,
				"is_cost": true,
				"subject": "self",
				"set_faceup": false},
				{"name": "move_card_to_container",
				"subject": "target",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			confirm._on_OptionalConfirmation_confirmed()
			confirm.hide()
		await yield_for(0.5)
		assert_true(card.targeting_arrow.is_targeting,
				"Card started targeting once dialogue accepted")
		await target_card(card,target)
		await yield_to(card._flip_tween, "finished", 0.5)
		assert_false(card.is_faceup,
				"Card should be face-down once the cost dialogue is accepted")

class TestScriptConfirmDialog:
	extends "res://tests/ScEng_common.gd"

	func test_script_confirm_dialog() -> void:
		var confirm
		card.scripts = {"manual": {
				"is_optional_board": true,
				"board": [
					{"name": "flip_card",
					"is_cost": true,
					"subject": "self",
					"set_faceup": false},
					{"name": "rotate_card",
					"subject": "self",
					"degrees":  180}]}}
		await table_move(card, Vector2(500,200))
		card.execute_scripts()
		confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			confirm._on_OptionalConfirmation_cancelled()
			confirm.hide()
		await yield_to(card._flip_tween, "finished", 0.5)
		assert_true(card.is_faceup,
				"Card has not have executed any tasks with canceled script dialog")
		assert_eq(0, card.card_rotation,
				"Card has not have executed any tasks with canceled script dialog")
		card.execute_scripts()
		confirm = board.get_node("OptionalConfirmation")
		assert_not_null(confirm)
		if confirm:
			confirm._on_OptionalConfirmation_confirmed()
			confirm.hide()
		await yield_to(card._flip_tween, "finished", 0.5)
		assert_false(card.is_faceup,
				"Card execute all tasks properly after script confirm")
		assert_eq(180, card.card_rotation,
				"Card execute all tasks properly after script confirm")

class TestAskIntegerWithCardMoves:
	extends "res://tests/ScEng_common.gd"

	func test_ask_integer_with_card_moves():
		target = deck.get_top_card()
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "ask_integer",
						"subject": "self",
						"ask_int_min": 1,
						"ask_int_max": 5,
					},
					{
						"name": "move_card_to_container",
						"src_container": "deck",
						"dest_container": "discard",
						"subject": "index",
						"subject_count": "retrieve_integer",
						"subject_index": "top"
						}]}}
		card.execute_scripts()
		var ask_integer = board.get_node("AskInteger")
		ask_integer.number = 2
		ask_integer.hide()
		await yield_to(target._tween, "finished", 0.5)
		await yield_to(target._tween, "finished", 0.5)
		assert_eq(2,discard.get_card_count(), "2 cards should have been discarded")

class TestAskIntegerWithModTokens:
	extends "res://tests/ScEng_common.gd"

	func test_ask_integer_with_mod_tokens():
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "ask_integer",
						"subject": "self",
						"ask_int_min": 1,
						"ask_int_max": 5,
					},
					{
						"name": "mod_tokens",
						"src_container": "deck",
						"modification": 'retrieve_integer',
						"subject": "self",
						"token_name":  "bio"
						}]}}
		card.execute_scripts()
		var ask_integer = board.get_node("AskInteger")
		ask_integer.number = 3
		ask_integer.hide()
		await yield_for(0.2)
		var bio_token: Token = card.tokens.get_token("bio")
		assert_eq(3,bio_token.count,"Token increased by specified amount")
