class_name IntegerLineEdit
extends LineEdit

signal int_changed_nok
signal int_changed_ok
signal int_entered(value)

var previous_text: String
var minimum: int
var maximum: int
var leading_zeroes_regex := RegEx.new()
export var prevent_invalid_text: bool

func _ready() -> void:
	# warning-ignore:return_value_discarded
	leading_zeroes_regex.compile("^0+([1-9]+)")
	# warning-ignore:return_value_discarded
	connect("text_changed", self, "_on_IntegerLineEdit_text_changed")
	# warning-ignore:return_value_discarded
	connect("text_entered", self, "_on_IntegerLineEdit_text_entered")

func _on_IntegerLineEdit_text_entered(new_text: String) -> void:
	if new_text.is_valid_integer() and \
			int(new_text) >= minimum \
			and int(new_text) <= maximum:
		emit_signal("int_entered", int(new_text))


func _on_IntegerLineEdit_text_changed(new_text: String) -> void:
	var leading_zeroes = leading_zeroes_regex.search(new_text)
	if leading_zeroes:
		text = leading_zeroes.get_string(1)
	if not new_text.is_valid_integer() or \
			int(new_text) < minimum \
			or int(new_text) > maximum:
		emit_signal("int_changed_nok")
		if prevent_invalid_text:
			text = previous_text
	else:
		emit_signal("int_changed_ok")
		previous_text = text
