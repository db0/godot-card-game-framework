extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	pass

func test_array_join():
	var test_arr := ['a','b','c','d']
	assert_eq("a - b - c - d",
			CFUtils.array_join(test_arr,' - '),
			"Array joined into string with separator")


func test_list_files_in_directory():
	var list := CFUtils.list_files_in_directory(
			"res://src/custom/cards/sets/")
	assert_eq(5,len(list), "There should be 5 files")
	list = CFUtils.list_files_in_directory(
			"res://src/custom/cards/sets/", "SetScripts_")
	assert_eq(2,len(list), "There should be 2 set files")
	assert_true(list.has("SetScripts_Demo1.gd"), "Should contain demo1")
	assert_true(list.has("SetScripts_Demo2.gd"), "Should contain demo2")


func test_load_card_definitions():
	var defs = cfc.load_card_definitions()
	var card_names := [
			"Rich Text Card",
			"Shaking Card",
			"Test Card 1",
			"Test Card 2",
			"Spawn Card",
			"Test Card 3",
			"Multiple Choices Test Card"]
	for card_name in card_names:
		assert_true(defs.has(card_name), "Card Name should exist in definitions")
