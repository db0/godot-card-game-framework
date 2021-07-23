# A container for a card instance which is meant to be placed in a grid container.
# It will also show a larger image of the card when moused-over
class_name CVGridCardObject
extends CenterContainer

var display_card: Card
var card_list_object

onready var preview_popup := $PreviewPopup

func _ready() -> void:
	rect_min_size = CFConst.CARD_SIZE


func setup(card_name) -> Card:
	display_card = cfc.instance_card(card_name)
	add_child(display_card)
	display_card.resize_recursively(display_card._control, CFConst.THUMBNAIL_SCALE)
	display_card.card_front.scale_to(CFConst.THUMBNAIL_SCALE)
	display_card.state = Card.CardState.DECKBUILDER_GRID
	rect_min_size = CFConst.CARD_SIZE * CFConst.THUMBNAIL_SCALE
	rect_size = rect_min_size
	return(display_card)


func _on_GridCardObject_mouse_entered() -> void:
	preview_popup.show_preview_card(display_card.canonical_name)


func _on_GridCardObject_mouse_exited() -> void:
	preview_popup.hide_preview_card()
