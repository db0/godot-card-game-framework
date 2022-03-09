extends "res://tests/UTcommon.gd"

class TestSpawnCard:
	extends "res://tests/ScEng_common.gd"

	func test_spawn_card():
		target.scripts = {"manual": {"hand": [
				{"name": "spawn_card",
				"card_name": "Spawn Card",
				"object_count": 3,
				"board_position":  Vector2(500,200)}]}}
		target.execute_scripts()
		assert_eq(3,board.get_card_count(),
			"Card spawned on board")
		card = board.get_card(0)
		assert_eq("res://src/custom/cards/Token.tscn",card.filename,
			"Card of the correct scene spawned")
		assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
			"Spawned card left in correct state")
		assert_almost_eq(Vector2(500,200),card.position,Vector2(2,2),
			"Card spawned in correct location")
		var offsetx = CFConst.CARD_SIZE.x * CFConst.PLAY_AREA_SCALE
		assert_almost_eq(Vector2(500 + offsetx * 2,200),
				board.get_card(2).position,Vector2(2,2),
				"Third Card spawned in correct location")
		target.scripts = {"manual": {"hand": [
				{"name": "spawn_card",
				"card_name": "Spawn Card",
				"object_count": 10,
				"grid_name":  "BoardPlacementGrid"}]}}
		target.execute_scripts()
		# Give time to the card to instance
		yield(yield_for(0.4), YIELD)
		assert_eq(7,board.get_card_count(),
			"5 Card spawned on grid")
		if board.get_card_count() > 1:
			card = board.get_card(3)
			assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
				"Spawned card left in correct state")
			assert_not_null(card._placement_slot,
					"Card should have moved to a grid slot")

class TestSpawnAndModifyCard:
	extends "res://tests/ScEng_common.gd"

	func test_spawn_and_modify_card():
		target.scripts = {"manual": {"hand": [
				{
					"name": "spawn_card",
					"card_name": "Spawn Card",
					"object_count": 1,
					"board_position":  Vector2(500,200)
				},
				{
					"name": "rotate_card",
					"subject": "previous",
					"degrees": 90
				}
			]}}
		target.execute_scripts()
		yield(yield_for(0.4), YIELD)
		card = board.get_card(0)
		assert_eq(card.card_rotation, 90,
				"Spawned card should be pre-selected to be rotated")

	func test_spawn_and_modify_card_properies():
		target.scripts = {"manual": {"hand": [
				{
					"name": "spawn_card",
					"card_name": "Spawn Card",
					"object_count": 1,
					"board_position":  Vector2(500,200)
				},
				{
					"name": "modify_properties",
					"subject": "previous",
					"set_properties": {
						"Cost": "+5",
						"Tags": ["Spawn"]
					},
				}
			]}}
		target.execute_scripts()
		yield(yield_for(0.4), YIELD)
		card = board.get_card(0)
		assert_eq(card.get_property("Cost"), 5,
				"Spawned card should have modified cost")
		assert_eq(card.get_property("Tags"), ["Spawn"],
				"Spawned card should have modified tags")
