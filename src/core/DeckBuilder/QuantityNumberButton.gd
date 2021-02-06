# A button with a special signal, which uses the button name
# as the value sent.
class_name QuantityNumberButton
extends Button

# Send when this button is pressed. It also sents the quantity
signal quantity_set(value)

# The amount of a singly card, this button marks as being in the deck
var quantity_number: int

func _ready() -> void:
	quantity_number = int(name)
	connect("pressed",self,"_on_button_pressed")


func _on_button_pressed() -> void:
	emit_signal("quantity_set",quantity_number)
