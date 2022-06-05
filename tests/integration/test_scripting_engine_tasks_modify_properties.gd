extends "res://tests/UTcommon.gd"

class TestModifyProperties:
	extends "res://tests/ScEng_common.gd"

	func before_each():
		.before_each()
		yield(yield_for(0.12), YIELD)
		card.modify_property("Cost", 5)
		card.modify_property("Power", 2)


	func test_modify_properties():
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Name": "GUT Test", "Type": "Orange"}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.canonical_name,"GUT Test",
				"Card name should be changed")
		assert_eq(card.get_property("Type"),"Orange",
				"Card type should be changed")
		assert_eq(card.card_front.card_labels["Type"].text,"Orange",
				"Type label adjusted properly")
		assert_eq(card.card_front.card_labels["Name"].text,"GUT Test",
				"Name label adjusted properly")

		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Cost": "+5"}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.get_property("Cost"),10,
				"Card cost increased")
		assert_eq(card.card_front.card_labels["Cost"].text,"10",
				"Number property label adjusted properly")
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Cost": "-4"}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(card.get_property("Cost"),2,
				"Card cost decreased")
		assert_eq(card.card_front.card_labels["Cost"].text,"2",
				"Number property label adjusted properly")
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.get_property("Cost"),0,
				"Card cost not below 0 ")
		assert_eq(card.card_front.card_labels["Cost"].text,"0",
				"Number property label adjusted properly")

class TestModifyPropertiesPerProperty:
	extends "res://tests/ScEng_common.gd"

	func before_each():
		.before_each()
		yield(yield_for(0.12), YIELD)
		card.modify_property("Cost", 5)
		card.modify_property("Power", 2)

	func test_modify_properties_per_property():
		card.scripts = {
			"manual": {
				"hand": [
					{
						"name": "modify_properties",
						"subject": "self",
						"set_properties": {"Cost": "+per_property"},
						"per_property":{
							"property_name":"Power",
							"subject":"self",
						},
					}
				]
			}
		}
		card.execute_scripts()
		assert_eq(card.get_property("Cost"),7,
				"Card cost increased by power amount")
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.card_front.card_labels["Cost"].text,"7",
				"Number property label adjusted properly")
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Cost": "+per_property"},
				"per_property":{
					"property_name":"Power",
					"subject":"self",
					"is_inverted": "true",
				},
				}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.get_property("Cost"),5,
				"Card cost decreased by power amount")
		assert_eq(card.card_front.card_labels["Cost"].text,"5",
				"Number property label adjusted properly")

class TestModifyTagProperty:
	extends "res://tests/ScEng_common.gd"

	func before_each():
		.before_each()
		yield(yield_for(0.12), YIELD)
		card.modify_property("Cost", 5)
		card.modify_property("Power", 2)

	func test_modify_tag_property():
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Tags": ["GUT Test","CGF"]}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.get_property("Tags"),["GUT Test","CGF"],
				"Tag properties adjusted")
		assert_eq(card.card_front.card_labels["Tags"].text, "GUT Test - CGF",
				"Array label adjusted")

class TestModifyStringNumberProperty:
	extends "res://tests/ScEng_common.gd"

	func before_each():
		.before_each()
		yield(yield_for(0.12), YIELD)
		card.modify_property("Cost", 5)
		card.modify_property("Power", 2)

	func test_modify_string_number_property():
		card.properties['Cost'] = 'X'
		card.properties['Power'] = 'X'
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Cost": '2', "Power": "-1"}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.properties.Cost, 2,
				"Card cost should be changed to to specified value")
		assert_eq(card.properties.Power, -1,
				"Card power should be set to int as comparison unexpected")

	func test_modify_string_number_property2():
		card.properties['Cost'] = 'X'
		card.properties['Power'] = '2'
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"set_properties": {"Cost": 'X', "Power": "X"}}]}}
		card.execute_scripts()
		yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
		assert_eq(card.properties.Cost, 'X',
				"Card cost should be changed to to specified value")
		assert_eq(card.properties.Power, 'X',
				"Card power should be set to string as comparison unexpected")

