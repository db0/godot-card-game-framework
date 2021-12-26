class_name CardBack
extends Panel

# This varialbe should hold the path to the node which is handling the way
# the card is viewed.
var viewed_node
# This bool will be set to true when we want to signify that the card is viewed
# while face down.
var is_viewed_visible : bool setget set_is_viewed_visible

# Stores a reference to the Card that is hosting this node
onready var card_owner = get_parent().get_parent().get_parent()


# This function can be overriden by any class extending CardBack
# to implement their own way of signifying a viewed face-down card
#
# If a card back does not include a viewed_node definition,this
# function will just show a warning.
func set_is_viewed_visible(value: bool) -> void:
	if viewed_node:
		viewed_node.visible = value
	else:
		print_debug("WARNING: viewed_node has not been defined in the card back: " + name)


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


# This is used to scale the card back when the card back is shown in the
# focus viewport.
#
# Override it according to the requirements of your card back
func scale_to(_scale_multiplier: float) -> void:
	pass
