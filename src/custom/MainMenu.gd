extends MarginContainer

onready var v_buttons := $VBox/Center/VButtons

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for option_button in v_buttons.get_children():
		if option_button.has_signal('pressed'):
			option_button.connect('pressed', self, 'on_button_pressed', [option_button.name])


func on_button_pressed(_button_name : String) -> void:
	match _button_name:
		"SinglePlayerDemo":
			get_tree().change_scene(CFConst.PATH_CUSTOM + 'CGFMain.tscn')
		"Multiplayer":
			pass
		"GUT":
			get_tree().change_scene("res://tests/tests.tscn")
		"Exit":
			get_tree().quit()

