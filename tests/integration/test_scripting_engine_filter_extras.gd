extends "res://tests/UTcommon.gd"

class TestFailCostOnSkip:
	extends "res://tests/ScEng_common.gd"

	func test_fail_cost_on_skip_false():
		# Gain 5 credits and 5 research if research >= 3
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 5,
				"is_cost": true,
				"filter_per_counter": {
					"counter_name": "research",
					"filter_count": 3,
				},
				"counter_name":  "credits"},
				{"name": "mod_counter",
				"modification": 5,
				"counter_name":  "research"}
				]}}
		card.execute_scripts()
		assert_eq(board.counters.get_counter("credits"),100,
				"Counter set to the specified amount")
		assert_eq(board.counters.get_counter("research"),5,
				"Counter set to the specified amount")

	func test_fail_cost_on_skip_true():
		# Gain 5 credits if research >= 3. Gain 5 research. 
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 5,
				"is_cost": true,
				"fail_cost_on_skip": true,
				"filter_per_counter": {
					"counter_name": "research",
					"filter_count": 3,
				},
				"counter_name":  "credits"},
				{"name": "mod_counter",
				"modification": 5,
				"counter_name":  "research"}
				]}}
		card.execute_scripts()
		assert_eq(board.counters.get_counter("credits"),100,
				"Counter set to the specified amount")
		assert_eq(board.counters.get_counter("research"),0,
				"Counter not modified because filter skipped")

class TestFilterStringNumberProperty:
	extends "res://tests/ScEng_common.gd"

	func test_filter_string_number_poperty():
		# 
		var vc = 'X'
		var card_to_modify: Card
		for c in hand.get_all_cards():
			if not card_to_modify:
				card_to_modify = c
				card_to_modify.modify_property("Cost", 5)
				continue
			else:
				c.modify_property("Cost", vc)
				if str(vc) == 'X':
					vc = 0
				else:
					vc = 'X'
		card.scripts = {"manual": {"hand": 
			[
				{
					"name": "modify_properties",
					"set_properties": {"Cost": "-1"},
					"subject": "tutor",
					"sort_by": "random",
					"src_container": "hand",
					"filter_state_tutor": [
						{
							"filter_properties": {
								"comparison": "ne",
								"Cost": 'X'
							},
							"filter_properties3": {
								"comparison": "ne",
								"Cost": 'U'
							},
							"filter_properties2": {
								"comparison": "ne",
								"Cost": 0
							},
						},
					]
				},
			]}}
		card.execute_scripts()
		assert_eq(card_to_modify.properties.Cost,4,
				"Card to modify set to correct amount")
		for c in hand.get_all_cards():
			if c != card_to_modify:
				assert_has([0, 'X'], c.properties.Cost, "All other cards left unmodified")
