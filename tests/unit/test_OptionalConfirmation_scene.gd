extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var test_script: Dictionary
var confirm: ConfirmationDialog

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	await setup_board()
	confirm = CFUtils._OPTIONAL_CONFIRM_SCENE.instantiate()

func test_title_and_buttons():
	confirm.prep("UT Card","UT Execution")
	assert_eq("Please Confirm...", confirm.get_window().title)
	assert_eq("UT Card: Do you want to activate UT Execution?", confirm.dialog_text)
	assert_eq("No", confirm.get_cancel_button().text)
	assert_eq("Yes", confirm.get_ok_button().text)

func test_no():
	watch_signals(confirm)
	confirm.prep("UT Test","UT Execution")
	confirm._on_OptionalConfirmation_cancelled()
	assert_signal_emitted(confirm,"selected")
	assert_false(confirm.is_accepted, "Should be false")

func test_yes():
	watch_signals(confirm)
	confirm.prep("UT Test","UT Execution")
	confirm._on_OptionalConfirmation_confirmed()
	assert_signal_emitted(confirm,"selected")
	assert_true(confirm.is_accepted, "Should be true")
