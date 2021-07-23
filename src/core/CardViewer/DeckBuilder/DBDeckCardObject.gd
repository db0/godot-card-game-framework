# An object displaying a card summary in the Deckbuilder's deck cards area
# and providing controls to adjust their quantity..
class_name DBDeckCardObject
extends HBoxContainer

# Sent when the user changes a card quantity directly from the deck area.
signal quantity_changed(value)

# The quantity of a specific card in the deck. 
# Placed in a label
var quantity: int 
# The card name which is displayed in the summary
var card_name: String

onready var _card_label:= $CardLabel

func _ready() -> void:
	pass


# This is used to prepare the values of this object
func setup(_card_name: String, count: int) -> void:
	card_name = _card_name
	set_quantity(count)
	_card_label.bbcode_text = _card_name
	# Because with rich Text labels, somehow it's not respecting the fill property.
	_card_label.rect_min_size = get_parent().rect_size
	yield(get_tree(), "idle_frame")


# Updates the Quantity label and variable
func set_quantity(value) -> void:
	quantity = value
	$CardCount.text = str(value) + 'x'


# Signals the linked ListCardObject to increase quantity by 1
func _on_Plus_pressed() -> void:
	emit_signal("quantity_changed", quantity + 1)


# Signals the linked ListCardObject to decrease quantity by 1
func _on_Minus_pressed() -> void:
	emit_signal("quantity_changed", quantity - 1)
