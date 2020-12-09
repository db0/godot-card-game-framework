extends "res://tests/UTcommon.gd"

const _CARD_OPTIONAL_CONFIRM = preload("res://src/core/OptionalConfirmation.tscn")
var cards := []
var card: Card
var test_script: Dictionary
var confirm: ConfirmationDialog

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
	confirm = _CARD_OPTIONAL_CONFIRM.instance()
	
func test_titlel_anb_buttons():
	confirm.prep("UT Card","UT Execution")
	assert_eq("Please Confirm...", confirm.window_title)
	assert_eq("UT Card: Do you want to activate UT Execution?", confirm.dialog_text)
	assert_eq("No", confirm.get_cancel().text)
	assert_eq("Yes", confirm.get_ok().text)

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
