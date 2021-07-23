
class_name DBGridCardObject
extends CVGridCardObject

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("gui_input",self,"on_gui_input")
	
func on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == 1:
			card_list_object._on_Plus_pressed()
		elif event.get_button_index() == 2:
			card_list_object._on_Minus_pressed()
		elif event.get_button_index() == 3:
			card_list_object.set_quantity(0)
