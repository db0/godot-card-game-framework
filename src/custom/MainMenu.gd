extends Panel

# The time it takes to switch from one menu tab to another
const menu_switch_time = 0.35

onready var v_buttons := $MainMenu/VBox/Center/VButtons
onready var main_menu := $MainMenu
onready var match_maker := $MatchMaker
onready var deck_builder := $DeckBuilder

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for option_button in v_buttons.get_children():
		if option_button.has_signal('pressed'):
			option_button.connect('pressed', self, 'on_button_pressed', [option_button.name])
	match_maker.rect_position.x = get_viewport().size.x
	deck_builder.rect_position.x = -get_viewport().size.x
	match_maker.back_button.connect("pressed", self, "on_button_pressed", ['match_maker_back'])
	deck_builder.back_button.connect("pressed", self, "on_button_pressed", ['deckbuilder_back'])
	get_viewport().connect("size_changed", self, '_on_Menu_resized')


func on_button_pressed(_button_name : String) -> void:
	match _button_name:
		"SinglePlayerDemo":
			get_tree().change_scene(CFConst.PATH_CUSTOM + 'CGFMain.tscn')
		"Multiplayer":
			switch_to_tab(match_maker)
		"GUT":
			get_tree().change_scene("res://tests/tests.tscn")
		"Deckbuilder":
			switch_to_tab(deck_builder)
		"Exit":
			get_tree().quit()
		"match_maker_back":
			switch_to_main_menu(match_maker)
		"deckbuilder_back":
			switch_to_main_menu(deck_builder)

func switch_to_tab(tab: Control) -> void:
	var main_position_x : float
	match tab:
		match_maker:
			main_position_x = -get_viewport().size.x
		deck_builder:
			main_position_x = get_viewport().size.x
	$MenuTween.interpolate_property(main_menu,'rect_position:x',
			main_menu.rect_position.x, main_position_x, menu_switch_time,
			Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$MenuTween.interpolate_property(tab,'rect_position:x',
			tab.rect_position.x, 0, menu_switch_time,
			Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$MenuTween.start()


func switch_to_main_menu(tab: Control) -> void:
	var tab_position_x : float
	match tab:
		match_maker:
			tab_position_x = get_viewport().size.x
		deck_builder:
			tab_position_x = -get_viewport().size.x
	$MenuTween.interpolate_property(tab,'rect_position:x',
			tab.rect_position.x, tab_position_x, menu_switch_time,
			Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$MenuTween.interpolate_property(main_menu,'rect_position:x',
			main_menu.rect_position.x, 0, menu_switch_time,
			Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$MenuTween.start()

func _on_Menu_resized() -> void:
	for tab in [main_menu, deck_builder, match_maker]:
		if is_instance_valid(tab):
			tab.rect_size = get_viewport().size
			if tab.rect_position.x < 0.0:
					tab.rect_position.x = -get_viewport().size.x
			elif tab.rect_position.x > 0.0:
					tab.rect_position.x = get_viewport().size.x
