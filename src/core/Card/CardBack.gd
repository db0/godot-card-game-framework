class_name CardBack
extends Panel

# Stores a reference to the Card that is hosting this node
onready var card_owner = get_parent().get_parent().get_parent()

# Each class which extends this has to overwrite this function
# with the one specific to its needs
#
# This is the generic function that will be called when the card back
# is visible to the player
func start_card_back_animation() -> void:
	pass

# Each class which extends this has to overwrite this function
# with the one specific to its needs
#
# This is the generic function that will be called when the card back
# stops being visible to the player.
func stop_card_back_animation() -> void:
	pass
