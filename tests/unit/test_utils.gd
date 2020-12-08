extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()

func test_array_join():
	var test_arr := ['a','b','c','d']
	assert_eq("a - b - c - d",
			CardFrameworkUtils.array_join(test_arr,' - '),
			"Array joined into string with separator")

func test_list_files_in_directory():
	var list := CardFrameworkUtils.list_files_in_directory(
			"res://src/custom/cards/sets/")
	assert_eq(5,len(list), "There should be 5 set files")
	list = CardFrameworkUtils.list_files_in_directory(
			"res://src/custom/cards/sets/", "SetScripts_")
	assert_eq(2,len(list), "There should be 2 set files")
	assert_eq(["SetScripts_Demo1.gd","SetScripts_Demo2.gd"],
			list, "List contents should be accurate")

func test_load_card_definitions():
	var defs := cfc.load_card_definitions()
	assert_eq(["Test Card 1", "Test Card 2", "Test Card 3", "Multiple Choices Test Card"], defs.keys(),
			"Card Definitions should be loaded from all sets")

func test_find_card_script():
	var card_script := CardFrameworkUtils.find_card_script("Test Card 1", "manual")
	var script_file = load("res://src/custom/cards/sets/SetScripts_Demo1.gd").new()
	# We compary dictionary hashes, because otherwise it tries to compare
	# references
	assert_true(card_script["hand"].hash() ==
			script_file.get_scripts("Test Card 1")["manual"]["hand"].hash(),
			"Card scripts sought in all sets")
	card_script = CardFrameworkUtils.find_card_script("Test Card 3", "card_rotated")
	script_file = load("res://src/custom/cards/sets/SetScripts_Demo2.gd").new()
	assert_eq(card_script["board"].hash(),
			script_file.get_scripts("Test Card 3")["card_rotated"]["board"].hash(),
			"Card scripts retrieved for correct trigger")
