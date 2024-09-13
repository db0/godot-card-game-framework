# A container for a card instance which is meant to be placed in a grid container.
# It will also show a larger image of the card when moused-over
class_name CVGridCardObject
extends CenterContainer

var display_card: Card
var card_list_object

@onready var preview_popup := $PreviewPopup


func _ready() -> void:
# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", Callable(self, '_on_viewport_resized'))

func setup(card) -> Card:
	if typeof(card) == TYPE_STRING:
		display_card = cfc.instance_card(card)
	else:
		display_card = card
		display_card.position = Vector2(0,0)
		display_card.scale = Vector2(1,1)
	add_child(display_card)
	display_card.set_owner(self)
	if CFConst.VIEWPORT_FOCUS_ZOOM_TYPE == "scale":
		display_card.scale = Vector2(1,1) * display_card.thumbnail_scale * cfc.curr_scale
	else:
		display_card.resize_recursively(display_card._control, display_card.thumbnail_scale * cfc.curr_scale)
		display_card.card_front.scale_to(display_card.thumbnail_scale * cfc.curr_scale)
	display_card.state = Card.CardState.DECKBUILDER_GRID
	custom_minimum_size = display_card.canonical_size * display_card.thumbnail_scale * cfc.curr_scale
	size = custom_minimum_size
	return(display_card)


func _on_GridCardObject_mouse_entered() -> void:
	preview_popup.show_preview_card(display_card.canonical_name)


func _on_GridCardObject_mouse_exited() -> void:
	preview_popup.hide_preview_card()


func get_class() -> String:
	# As far as I can tell this is never used, but it wouldn't work as expected
	# Godot will not override the built-in get_class() and that won't show class_name
	return("CVGridCardObject")


# Resizes the grid container so that the preview cards fix snuggly.
func _on_viewport_resized() -> void:
	custom_minimum_size = display_card.canonical_size * display_card.thumbnail_scale * cfc.curr_scale
	size = custom_minimum_size
