extends Panel

# The time it takes to switch from one menu tab to another
const menu_switch_time = 0.35

@onready var v_buttons := $MainMenu/VBox/Center/VButtons
@onready var main_menu := $MainMenu
#onready var settings_menu := $SettingsMenu
@onready var deck_builder := $DeckBuilder
@onready var card_library := $CardLibrary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for option_button in v_buttons.get_children():
		if option_button.has_signal('pressed'):
			option_button.connect('pressed', Callable(self, 'on_button_pressed').bind(option_button.name))
#	settings_menu.rect_position.x = get_viewport().size.x
	deck_builder.position.x = -get_viewport().size.x
	card_library.position.x = -get_viewport().size.x
#	settings_menu.back_button.connect("pressed", self, "_on_Setings_Back_pressed")
#	settings_menu.recover_prebuilts.connect("pressed", self, "_on_PreBuilts_pressed")
	deck_builder.back_button.connect("pressed", Callable(self, "_on_DeckBuilder_Back_pressed"))
	card_library.back_button.connect("pressed", Callable(self, "_on_CardLibrary_Back_pressed"))
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", Callable(self, '_on_Menu_resized'))


func on_button_pressed(_button_name : String) -> void:
	match _button_name:
		"SinglePlayerDemo":
			# warning-ignore:return_value_discarded
			get_tree().change_scene_to_file(CFConst.PATH_CUSTOM + 'CGFMain.tscn')
		"Multiplayer":
			pass
		"GUT":
			# warning-ignore:return_value_discarded
			get_tree().change_scene_to_file("res://tests/tests.tscn")
		"Deckbuilder":
			switch_to_tab(deck_builder)
		"CardLibrary":
			switch_to_tab(card_library)
		"Exit":
			get_tree().quit()

func switch_to_tab(tab: Control) -> void:
	var main_position_x : float
	match tab:
#		settings_menu:
#			main_position_x = -get_viewport().size.x
		deck_builder, card_library:
			main_position_x = get_viewport().size.x
	var tween: Tween
	if tween:
		tween.kill()
	tween = get_tree().create_tween().set_parallel(true)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(main_menu,'position:x', main_position_x, menu_switch_time)
	tween.tween_property(tab,'position:x', 0, menu_switch_time)
	tween.play()


func switch_to_main_menu(tab: Control) -> void:
	var tab_position_x : float
	match tab:
#		settings_menu:
#			tab_position_x = get_viewport().size.x
		deck_builder, card_library:
			tab_position_x = -get_viewport().size.x
	var tween: Tween
	if tween:
		tween.kill()
	tween = get_tree().create_tween().set_parallel(true)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tab,'position:x', tab_position_x, menu_switch_time)
	tween.tween_property(main_menu,'position:x', 0, menu_switch_time)
	tween.play()

func _on_DeckBuilder_Back_pressed() -> void:
	switch_to_main_menu(deck_builder)
	
func _on_CardLibrary_Back_pressed() -> void:
	switch_to_main_menu(card_library)
	
func _on_Menu_resized() -> void:
	for tab in [main_menu, deck_builder, card_library]:
		if is_instance_valid(tab):
			tab.size = get_viewport().size
			if tab.position.x < 0.0:
					tab.position.x = -get_viewport().size.x
			elif tab.position.x > 0.0:
					tab.position.x = get_viewport().size.x
