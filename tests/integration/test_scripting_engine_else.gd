extends "res://tests/UTcommon.gd"

class TestElse:
	extends "res://tests/ScEng_common.gd"

	func test_else():
		card.scripts = {"manual": {"board": [
				{"name": "rotate_card",
				"subject": "self",
				"is_cost": true,
				"degrees": 90},
				{"name": "mod_counter",
				"modification": 1,
				"counter_name":  "research"},
				{"name": "mod_counter",
				"modification": -10,
				"counter_name":  "credits"},]}}
		yield(table_move(card, Vector2(100,200)), "completed")
		card.execute_scripts()
		assert_eq(1,board.counters.get_counter("research"),
				"Counter increased because rotation cost could be paid")
		card.execute_scripts()
		assert_eq(90,board.counters.get_counter("credits"),
				"Counter decreased because rotation cost could be paid")

