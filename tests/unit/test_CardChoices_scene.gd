extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var choices: Dictionary
var menu: PopupMenu

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	setup_board()
	menu = Card._CARD_CHOICES_SCENE.instance()
	choices = {"Test Choice 1": "Test1", "Test Choice 2": "Test2"}

func test_title_and_signal():
	watch_signals(menu)
	menu.prep("Unit Testing",choices)
	assert_eq("Please choose option for Unit Testing",menu.get_item_text(0),
			"Title is set according to Card Name")
	menu._on_CardChoices_id_pressed(0)
	menu.hide()
	assert_signal_emitted(menu,"id_pressed")

func test_choices_text():
	menu.prep("Unit Testing",choices)
	menu._on_CardChoices_id_pressed(4)
	assert_eq("Test Choice 2",menu.selected_key,
			"Option is the dict key")
