extends "res://tests/UTcommon.gd"

class TestShuffle:
	extends "res://tests/ScEng_common.gd"

	func test_shuffle():
		card.scripts = {"manual": {"hand": [
				{"name": "shuffle_container",
				"dest_container": "deck",},
				{"name": "mod_counter",
				"modification": 2,
				"counter_name": "research"}]}}
		card.execute_scripts()
		yield(yield_to(deck, "shuffle_completed", 1.5), YIELD)
		assert_eq(2,board.counters.get_counter("research"),
				"Counter increased by specified amount")
