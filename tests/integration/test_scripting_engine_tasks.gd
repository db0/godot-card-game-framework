extends "res://tests/UTcommon.gd"

class TestCustomScript:
	extends "res://tests/ScEng_common.gd"

	# Checks that custom scripts fire correctly
	func test_custom_script():
		card = cards[2]
		# Custom scripts have to be predefined in code
		# So not possible to specify them as runtime scripts
		card.execute_scripts()
		yield(yield_for(0.1), YIELD)
		assert_freed(card, "Test Card 2")
		card = cards[1]
		target = cards[3]
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_for(0.3), YIELD)
		assert_freed(target, "Test Card 1")

class TestRotateCard:
	extends "res://tests/ScEng_common.gd"

	func test_rotate_card():
		card.scripts = {"manual": {"board": [
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 90}]}}
		yield(table_move(card, Vector2(100,200)), "completed")
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_eq(card.card_rotation, 90,
				"Card should be rotated 90 degrees")

class TestFlipCard:
	extends "res://tests/ScEng_common.gd"

	func test_flip_card():
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "target",
					"set_faceup": false}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(target.is_faceup,
				"Target should be face-down")
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "target",
					"set_faceup": true}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_true(target.is_faceup,
				"Target should be face-up again")

class TestViewCard:
	extends "res://tests/ScEng_common.gd"

	func test_view_card():
		target.is_faceup = false
		card.scripts = {"manual": {"hand": [
					{"name": "view_card",
					"subject": "target"}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		assert_true(target.is_viewed,
				"Target should be viewed")
		target = cfc.NMAP.deck.get_top_card()
		card.scripts = {"manual": {"hand": [
					{"name": "view_card",
					"src_container": "deck",
					"subject_index": "top",
					"subject": "index"}]}}
		card.execute_scripts()
		assert_true(target.is_viewed,
				"Target should be viewed")

class TestMoveCardToContainer:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_to_container():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "self",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(cfc.NMAP.discard,card.get_parent(),
				"Card should have moved to discard pile")
		card = cards[1]
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "self",
				"dest_index": 5,
				"dest_container": "deck"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(cfc.NMAP.deck,card.get_parent(),
				"Card should have moved to deck")
		assert_eq(5,card.get_my_card_index(),
				"Card should have moved to index 5")


class TestMoveCardHandToBoard:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_hand_to_board():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"subject": "self",
				"board_position":  Vector2(100,100)}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(cfc.NMAP.board,card.get_parent(),
				"Card should have moved to board")
		assert_eq(Vector2(100,100),card.global_position,
				"Card should have moved to specified position")

class TestMoveCard:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_cont_to_cont():
		target = cfc.NMAP.deck.get_card(5)
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": 5,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(cfc.NMAP.discard,target.get_parent(),
				"Card should have moved to discard pile")
		target = cfc.NMAP.deck.get_card(3)
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": 3,
				"dest_index": 1,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_eq(cfc.NMAP.discard,target.get_parent(),
				"Card should have moved to discard")
		assert_eq(1,target.get_my_card_index(),
				"Card should have moved to index 1")

	func test_move_card_cont_to_board():
		yield(yield_for(0.2), YIELD)
		target = cfc.NMAP.deck.get_card(5)
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"subject": "index",
				"subject_index": 5,
				"src_container": "deck",
				"board_position":  Vector2(1000,200)}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_for(0.2), YIELD)
		assert_almost_eq(Vector2(1000,200),target.global_position, Vector2(5,5),
				"Card should have moved to specified board position")
		target = cfc.NMAP.deck.get_card(0)
		var target2 = cfc.NMAP.deck.get_card(1)
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"subject": "index",
				"subject_count": 4,
				"subject_index": "bottom",
				"src_container": "deck",
				"grid_name":  "BoardPlacementGrid"}]}}
		board.get_node("BoardPlacementGrid").visible = true
		yield(execute_with_yield(card), "completed")
		assert_not_null(target._placement_slot,
				"Card should have moved to a grid slot")
		assert_not_null(target2._placement_slot,
				"Card should have moved to a grid slot")
		if target._placement_slot:
			assert_eq(target._placement_slot.get_grid_name(), "BoardPlacementGrid",
					"Card placed in the correct grid")
			assert_ne(target._placement_slot, target2._placement_slot,
					"Cards not placed in the same slot")

class TestModToken:
	extends "res://tests/ScEng_common.gd"

	func test_mod_tokens():
		target.scripts = {"manual": {"hand": [
				{"name": "mod_tokens",
				"subject": "self",
				"modification": 5,
				"token_name":  "industry"}]}}
		target.execute_scripts()
		var industry_token: Token = target.tokens.get_token("industry")
		assert_eq(5,industry_token.count,"Token increased by specified amount")
		card.scripts = {"manual": {"hand": [
				{"name": "mod_tokens",
				"subject": "target",
				"modification": 2,
				"set_to_mod": true,
				"token_name":  "industry"}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		# My scripts are slower now
		yield(yield_for(0.2), YIELD)
		assert_eq(2,industry_token.count,"Token set to specified amount")

class TestShuffleContainer:
	extends "res://tests/ScEng_common.gd"

	func test_shuffle_container():
		card.scripts = {"manual": {"hand": [
				{"name": "shuffle_container",
				"dest_container": "hand"}]}}
		var original_card_order = hand.get_all_cards()
		var rng_threshold: int = 0
		watch_signals(hand)
		card.call_deferred("execute_scripts")
		yield(hand, "shuffle_completed")
		if original_card_order == hand.get_all_cards():
			gut.p(original_card_order)
			rng_threshold += 1
		card.call_deferred("execute_scripts")
		yield(hand, "shuffle_completed")
		if original_card_order == hand.get_all_cards():
			gut.p(original_card_order)
			rng_threshold += 1
		card.call_deferred("execute_scripts")
		yield(hand, "shuffle_completed")
		if original_card_order == hand.get_all_cards():
			gut.p(original_card_order)
			rng_threshold += 1
		card.call_deferred("execute_scripts")
		yield(hand, "shuffle_completed")
		if original_card_order == hand.get_all_cards():
			gut.p(original_card_order)
			rng_threshold += 1
		# We allow for the random chance that the shuffle ended with the same order once
		assert_lt(rng_threshold,2,
			"Card should not fall in he same spot too many times")
		assert_signal_emit_count(hand, "shuffle_completed", 4)

class TestAttachCard:
	extends "res://tests/ScEng_common.gd"

	func test_attach_to_card():
		yield(table_move(target, Vector2(500,400)), "completed")
		card.scripts = {"manual": {"hand": [
				{"name": "attach_to_card",
				"subject": "target"}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(card.current_host_card,target,
				"Card has been hosted on the target")

class TestHostCard:
	extends "res://tests/ScEng_common.gd"

	func test_host_card():
		yield(table_move(card, Vector2(500,400)), "completed")
		card.scripts = {"manual": {"board": [
				{"name": "host_card",
				"subject": "target"}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(target.current_host_card,card,
				"target has been hosted on the card")

class TestCreateGrid:
	extends "res://tests/ScEng_common.gd"

	func test_create_grid():
		card.scripts = {"manual": {"hand": [
				{"name": "add_grid",
				"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
				"object_count": 2,
				"board_position":  Vector2(50,50)}]}}
		yield(execute_with_yield(card), "completed")
		var grids: Array = get_tree().get_nodes_in_group("placement_grid")
		assert_eq(grids.size(), 3, "All grids were created")
		card.scripts = {"manual": {"hand": [
				{"name": "add_grid",
				"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
				"grid_name": "GUT Grid",
				"object_count": 3,
				"board_position":  Vector2(600,50)}]}}
		yield(execute_with_yield(card), "completed")
		var gut_grids := []
		for g in get_tree().get_nodes_in_group("placement_grid"):
			if not g in grids:
				gut_grids.append(g)
		for grid in gut_grids:
			assert_eq(grid.name_label.text, "GUT Grid",
					"Created grid has correct label")

class TestModCounters:
	extends "res://tests/ScEng_common.gd"

	func test_mod_counter():
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 5,
				"counter_name":  "research"}]}}
		card.execute_scripts()
		assert_eq(5,board.counters.get_counter("research"),
				"Counter increased by specified amount")
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 2,
				"set_to_mod": true,
				"counter_name": "credits"}]}}
		card.execute_scripts()
		assert_eq(2,board.counters.get_counter("credits"),
				"Counter set to the specified amount")

	func test_draw_more_cards_than_pile_max():
		target = deck.get_last_card()
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "top",
				"subject_count": 50,
				"is_cost": true,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_eq(target.get_parent(),deck,
				"Card is not moved because more than max requested as cost")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "top",
				"subject_count": 50,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_eq(target.get_parent(),discard,
				"Card is moved even though more than requested because it not cost")
