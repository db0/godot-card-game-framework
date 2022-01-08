extends "res://tests/UTcommon.gd"

var cards := []

const token_scene = TokenDrawer._TOKEN_SCENE
var token: Token

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	token = token_scene.instance()
	token.setup("tech")
	board.add_child(token)

func test_count_setget():
	var count_label = token.get_node("CenterContainer/Count")
	assert_eq(0,token.count,"Initial count should be 0")
	assert_eq("0",count_label.text,"Label should be '0'")
	token.count += 2
	assert_eq(2,token.count,"Count should be 2")
	assert_eq("2",count_label.text,"Label should be '2'")
	token.count += 5
	assert_eq(7,token.count,"Count should be 7")
	assert_eq("7",count_label.text,"Label should be '7'")
	token.count -= 3
	assert_eq(4,token.count,"Count should be 4")
	assert_eq("4",count_label.text,"Label should be '4'")
	token.count = 10
	assert_eq(10,token.count,"Count should be 10")
	assert_eq("10",count_label.text,"Label should be '10'")
	token.count = -100
	assert_eq(0,token.count,"Count should be 0")
	assert_eq("0",count_label.text,"Label should be '0'")

func test_expand_retract():
	var tname = token.get_node("Name")
	var tcont= token.get_node("MarginContainer")
	var tbuttons = token.get_node("Buttons")
	assert_false(tname.visible, "should be false on setup")
	assert_false(tcont.visible, "should be false on setup")
	assert_false(tbuttons.visible, "should be false on setup")
	token.expand()
	assert_true(tname.visible, "should be true on expand")
	assert_true(tcont.visible, "should be true on expand")
	assert_true(tbuttons.visible, "should be true on expand")
	token.retract()
	assert_false(tname.visible, "should be false on retract")
	assert_false(tcont.visible, "should be false on retract")
	assert_false(tbuttons.visible, "should be false on retract")

func test_buttons():
	token._on_Add_pressed()
	assert_eq(1,token.count,"count should be 1")
	token._on_Add_pressed()
	assert_eq(2,token.count,"count should be 2")
	token._on_Remove_pressed()
	assert_eq(1,token.count,"count should be 1")
	token._on_Remove_pressed()
	yield(yield_for(0.01), YIELD) # Wait for queue free
	assert_freed(token, "Token")

func test_get_token_name():
	var token2 = token_scene.instance()
	token2.setup("tech")
	board.add_child(token2)
	assert_eq("tech",token2.get_token_name(),
			"Returned name should be lowercase")
	assert_ne("Tech",token2.name,
			"name property is godot-unique")
