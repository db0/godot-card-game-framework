extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")

func test_array_join():
	var test_arr := ['a','b','c','d']
	assert_eq("a - b - c - d",
			CFUtils.array_join(test_arr,' - '),
			"Array joined into string with separator")

func test_list_files_in_directory():
	var list := CFUtils.list_files_in_directory(
			"res://src/custom/cards/sets/")
	assert_eq(4,len(list), "There should be 5 set files")
	list = CFUtils.list_files_in_directory(
			"res://src/custom/cards/sets/", "SetScripts_")
	assert_eq(2,len(list), "There should be 2 set files")
	assert_eq(["SetScripts_Demo1.gd","SetScripts_Demo2.gd"],
			list, "List contents should be accurate")

func test_load_card_definitions():
	var defs := cfc.load_card_definitions()
	assert_eq(["Test Card 1", "Test Card 2", "Test Card 3", "Multiple Choices Test Card"], defs.keys(),
			"Card Definitions should be loaded from all sets")

