# Sets and modulates the highlight of a Card of CardContainer scene
class_name Highlight
extends Control

# Stores a reference to the Card that is hosting this node
onready var owner_node = get_parent().get_parent()

func _ready() -> void:
	pass

# Changes card highlight colour.
func set_highlight(requestedFocus: bool, hoverColour = CFConst.HOST_HOVER_COLOUR) -> void:
	visible = requestedFocus
	if requestedFocus:
		modulate = hoverColour
	else:
		modulate = CFConst.FOCUS_HOVER_COLOUR


# Goes through all the potential cards we're currently hovering onto with a card
# or targetting arrow, and highlights the one with the highest index among
# their common parent.
# It also colours the highlight with the provided colour
func highlight_potential_card(colour : Color, potential_cards: Array) -> void:
	for idx in range(0,len(potential_cards)):
			# The last card in the sorted array is always the highest index
		if idx == len(potential_cards) - 1:
			potential_cards[idx].highlight.set_highlight(true,colour)
		else:
			potential_cards[idx].highlight.set_highlight(false)


# Goes through all the potential cards we're currently hovering onto with a card
# or targetting arrow, and highlights the one with the highest index among
# their common parent.
# It also colours the highlight with the provided colour
func highlight_potential_container(colour : Color, potential_containers: Array) -> void:
	for idx in range(0,len(potential_containers)):
		if idx == len(potential_containers) - 1:
			potential_containers[idx].highlight.set_highlight(true,colour)
		else:
			potential_containers[idx].highlight.set_highlight(false)


