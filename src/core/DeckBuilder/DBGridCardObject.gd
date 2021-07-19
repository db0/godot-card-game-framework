
class_name DBGridCardObject
extends CenterContainer

var display_card: Card
var card_list_object

onready var preview_popup := $PreviewPopup

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("gui_input",self,"on_gui_input")
	rect_min_size = CFConst.CARD_SIZE

func on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == 1:
			card_list_object._on_Plus_pressed()
		elif event.get_button_index() == 2:
			card_list_object._on_Minus_pressed()
		elif event.get_button_index() == 3:
			card_list_object.set_quantity(0)

func setup(card_name) -> Card:
	display_card = cfc.instance_card(card_name)
	add_child(display_card)
	display_card.resize_recursively(display_card._control, CFConst.THUMBNAIL_SCALE)
	display_card.card_front.scale_to(CFConst.THUMBNAIL_SCALE)
	display_card.state = Card.CardState.DECKBUILDER_GRID
	rect_min_size = CFConst.CARD_SIZE * CFConst.THUMBNAIL_SCALE
	rect_size = rect_min_size
	return(display_card)


func _on_DBGridCardObject_mouse_entered() -> void:
	preview_popup.show_preview_card(display_card.canonical_name)


func _on_DBGridCardObject_mouse_exited() -> void:
	preview_popup.hide_preview_card()
