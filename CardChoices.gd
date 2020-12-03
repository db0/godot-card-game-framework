# Pops up a menu for the player to choose on of the card
# options
extends PopupMenu

var id_selected: int
var selected_key: String

# Called from Card.execute_scripts() when a card has multiple options.
#
# It prepares the menu items based on the dictionary keys and bring the
# popup to the front.
func prep(owner_card, script_with_choices: Dictionary) -> void:
		set_item_text(0, "Please choose option for " + owner_card.card_name)
		# The dictionary passed is a card script which contains
		# an extra dictionary before the task definitions
		# When that happens, it specifies multiple choice
		# and the dictionary keys, are the choices in human-readable text.
		for key in script_with_choices.keys():
			add_item(key)
		cfc.NMAP.board.add_child(self)
		popup()
		# One again we need two different Panels due to 
		# https://github.com/godotengine/godot/issues/32030
		$HorizontalHighlights.rect_size = rect_size
		$VecticalHighlights.rect_size = rect_size
		# We spawn the dialogue at the middle of the screen.
		rect_global_position = get_viewport().size/2 - rect_size/2

func _on_CardChoices_id_pressed(id: int) -> void:
	id_selected = id
	selected_key = get_item_text(id)

# It ensures the "id_pressed" signal is emited even when no choice has
# been made, to allow the script execution to continue and not
# leave yields waiting
func _on_CardChoices_popup_hide() -> void:
	if not id_selected:
		emit_signal("id_pressed", 0)