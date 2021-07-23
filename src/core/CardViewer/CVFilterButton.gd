# A Card Viewer button which is hides/shows all cards which match its text
class_name CVFilterButton
extends Button

signal right_pressed()

var property : String
var value: String


func setup(_property: String, _value: String) -> void:
	property = _property
	value = _value
	text = _value
	name = _value


func _on_CVFilterButton_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton\
			and event.is_pressed()\
			and event.get_button_index() == 2:
		pressed = true
		emit_signal("right_pressed")
