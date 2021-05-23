extends MarginContainer

onready var v_buttons = get_node('VBox/Center/VButtons') as VBoxContainer
# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in v_buttons.get_child_count():
		if !v_buttons.get_child(i).has_signal('pressed'):
			continue
		v_buttons.get_child(i).connect('pressed', self, 'on_button_pressed', [i])
#END

func on_button_pressed(_indx : int) -> void:
	match _indx:
		0: #NewGame
			pass
		1: #Test
			var _ok = get_tree().change_scene('res://src/custom/CGFMain.tscn')
		2: #Options
			pass
		3: #Exit
			get_tree().quit()
#END

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
