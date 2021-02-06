class_name DBFilterButton
extends Button

signal filter_toggled()

var property : String
var value: String

func setup(_property: String, _value: String) -> void:
	property = _property
	value = _value
	text = value

func _ready() -> void:
	pass
	# warning-ignore:return_value_discarded
#	connect("pressed", self, "_on_pressed")

#func _on_toggle(button_pressed) -> void:
#	emit_signal("filter_toggled", filter, button_pressed)
#
