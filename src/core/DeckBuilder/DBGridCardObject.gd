
class_name DBGridCardObject
extends CenterContainer

var display_card: Card
var card_list_object

onready var preview_popup := $PreviewPopup

func _ready() -> void:
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

func setup(card_name) -> void:
	display_card = cfc.instance_card(card_name)
	add_child(display_card)
	display_card.state = Card.CardState.DECKBUILDER_GRID
	

func _on_DBGridCardObject_mouse_entered() -> void:
	preview_popup.show_preview_card(display_card.canonical_name)


func _on_DBGridCardObject_mouse_exited() -> void:
	preview_popup.hide_preview_card()
