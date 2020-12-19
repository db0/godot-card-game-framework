extends ManipulationButtons


func _ready() -> void:
	# The methods to use each of these should be defined in this script
	needed_buttons = {
		"Rot90": "T",
		"Rot180": "@",
		"Flip": "F",
		"AddToken": "O",
		"View": "V",
	}
	spawn_manipulation_buttons()

# Hover button which rotates the card 90 degrees
func _on_Rot90_pressed() -> void:
# warning-ignore:return_value_discarded
	owner_node.set_card_rotation(90, true)


# Hover button which rotates the card 180 degrees
func _on_Rot180_pressed() -> void:
# warning-ignore:return_value_discarded
	owner_node.set_card_rotation(180, true)


# Hover button which flips the card facedown/faceup
func _on_Flip_pressed() -> void:
	# warning-ignore:return_value_discarded
	owner_node.set_is_faceup(not owner_node.is_faceup)


# Demo hover button which adds a selection of random tokens
func _on_AddToken_pressed() -> void:
	var valid_tokens := ['tech','gold coin','blood','plasma']
	# warning-ignore:return_value_discarded
	owner_node.tokens.mod_token(valid_tokens[CFUtils.randi() % len(valid_tokens)], 1)


# Hover button which allows the player to view a facedown card
func _on_View_pressed() -> void:
	# warning-ignore:return_value_discarded
	owner_node.set_is_viewed(true)

