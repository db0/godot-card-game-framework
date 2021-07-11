# Sets and modulates the highlight of a Card of CardContainer scene
class_name Highlight
extends Control

# Stores a reference to the Card that is hosting this node
onready var owner_node = get_parent().get_parent()
onready var _left_right := $LeftRight
onready var _top_bottom := $TopBottom

func _ready() -> void:
	pass

# Changes card highlight colour.
func set_highlight(requestedFocus: bool,
		hoverColour = CFConst.HOST_HOVER_COLOUR) -> void:
	visible = requestedFocus
	if requestedFocus:
		modulate = hoverColour
	else:
		modulate = CFConst.FOCUS_HOVER_COLOUR


# Goes through all the potential cards we're currently hovering onto with the mouse
# or targetting arrow, and highlights the one with the highest index among
# their common parent.
#
# It also clears the highlights of any grid placement slots that might
# have been already highlighted, since potential card targets/hosts take
# priority.
#
# It also colours the highlight with the specified colour
static func highlight_potential_card(colour : Color,
		potential_cards: Array,
		potential_slots := []) -> Card:
	potential_cards.sort_custom(CFUtils,"sort_index_ascending")
	for idx in range(0,len(potential_cards)):
			# The last card in the sorted array is always the highest index
		if idx == len(potential_cards) - 1:
			potential_cards[idx].highlight.set_highlight(true,colour)
		else:
			potential_cards[idx].highlight.set_highlight(false)
	for slot in potential_slots:
		slot.set_highlight(false)
	return(potential_cards.back())

# Goes through all the potential cardcontainers we're currently hovering onto
# with the mouse, and highlights the one with the highest index among
# their common parent.
#
# It also clears the highlights of any porential hosts or
# grid placement slots that might have been already highlighted, since
# CardContainers take priority
#
# It also colours the highlight with the specified colour
static func highlight_potential_container(colour : Color,
		potential_containers: Array,
		potential_cards := [],
		potential_slots := []) -> CardContainer:
	potential_containers.sort_custom(CFUtils,"sort_card_containers")
	for idx in range(0,len(potential_containers)):
		if idx == len(potential_containers) - 1:
			potential_containers[idx].highlight.set_highlight(true,colour)
		else:
			potential_containers[idx].highlight.set_highlight(false)
	for card in potential_cards:
		card.highlight.set_highlight(false)
	for slot in potential_slots:
		slot.set_highlight(false)
	return(potential_containers.back())

