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
	assert_eq(card.card_front.card_labels["Cost"].text,"Cost: 10",
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
	assert_eq(card.card_front.card_labels["Cost"].text,"Cost: 2",
			"Number property label adjusted properly")
	card.execute_scripts()
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(card.get_property("Cost"),0,
			"Card cost not below 0 ")
	assert_eq(card.card_front.card_labels["Cost"].text,"Cost: 0",
			"Number property label adjusted properly")


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
	assert_eq(card.card_front.card_labels["Cost"].text,"Cost: 7",
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
	assert_eq(card.card_front.card_labels["Cost"].text,"Cost: 5",
			"Number property label adjusted properly")


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
