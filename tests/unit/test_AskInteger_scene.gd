extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var test_script: Dictionary
var ask_integer: AcceptDialog
var hh: Panel
var vh: Panel
var line: LineEdit

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	await setup_board()
	ask_integer = ScriptingEngine._ASK_INTEGER_SCENE.instantiate()
	hh = ask_integer.get_node("HorizontalHighlights")
	vh = ask_integer.get_node("VecticalHighlights")
	line = ask_integer.get_node("IntegerLineEdit")

func after_each():
	cfc.quit_game()


func test_title_and_highlights():
	ask_integer.prep("UT Card",1,5)
	assert_eq("Please enter number for the effect of UT Card", ask_integer.title)
	assert_eq("Submit", ask_integer.get_ok_button().text)
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)

func test_on_LineEdit_text_changed():
	ask_integer.prep("UT Card",1,5)
	line.text = "1"
	line._on_IntegerLineEdit_text_changed("1")
	assert_eq(Color(0,1.6,0), hh.modulate)
	assert_eq(Color(0,1.4,0), vh.modulate)
	assert_eq(0,ask_integer.number)
	line.text = "11"
	line._on_IntegerLineEdit_text_changed("11")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	ask_integer._on_AskInteger_confirmed()
	assert_true(ask_integer.visible)
	line.text = "0"
	line._on_IntegerLineEdit_text_changed("0")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	line.text = "-1"
	line._on_IntegerLineEdit_text_changed("-1")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	line.text = ""
	line._on_IntegerLineEdit_text_changed("")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	ask_integer._on_AskInteger_confirmed()
	assert_true(ask_integer.visible)
	line.text = "abc"
	line._on_IntegerLineEdit_text_changed("abc")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	ask_integer._on_AskInteger_confirmed()
	assert_true(ask_integer.visible)
	line.text = "0005"
	line._on_IntegerLineEdit_text_changed("0005")
	assert_eq(Color(0,1.6,0), hh.modulate)
	assert_eq(Color(0,1.4,0), vh.modulate)
	assert_eq("5",line.text)
	line.text = "10005"
	line._on_IntegerLineEdit_text_changed("10005")
	assert_eq(Color(1.4,0,0), hh.modulate)
	assert_eq(Color(1.2,0,0), vh.modulate)
	assert_eq("10005",line.text)

func test_submit():
	watch_signals(ask_integer)
	ask_integer.prep("UT Card",1,5)
	ask_integer._on_AskInteger_confirmed()
	await yield_for(0.1)
	assert_eq(0,ask_integer.number)
	assert_signal_not_emitted(ask_integer,"popup_hide")
	line.text = "11"
	line._on_IntegerLineEdit_text_changed("11")
	ask_integer._on_AskInteger_confirmed()
	await yield_for(0.1)
	assert_eq(0,ask_integer.number)
	assert_signal_not_emitted(ask_integer,"popup_hide")
	line.text = "abd"
	line._on_IntegerLineEdit_text_changed("abd")
	ask_integer._on_AskInteger_confirmed()
	await yield_for(0.1)
	assert_eq(0,ask_integer.number)
	assert_signal_not_emitted(ask_integer,"popup_hide")
	line.text = "2"
	line._on_IntegerLineEdit_text_changed("2")
	ask_integer._on_AskInteger_confirmed()
	await yield_for(0.1)
	assert_signal_emitted(ask_integer,"popup_hide")
	assert_eq(2,ask_integer.number)

