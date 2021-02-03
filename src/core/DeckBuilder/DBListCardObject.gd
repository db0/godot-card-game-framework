# An object displaying a card summary in the Deckbuilder available cards area
# and providing controls to add it to the deck.
class_name DBListCardObject
extends HBoxContainer

# A potential link to the card summary in the deck itself.
# If it is null, it will be created as soon as the card is added to the deck
var deck_card_object: DBDeckCardObject
# A pointer back to the deckbuilder scene
var deckbuilder
# The max quantity allowed for this particular card
var max_allowed: int

# The amount of this card selected to be added to the deck.
var quantity: int setget set_quantity
# The properties of the card, used for filtering
var card_properties: Dictionary
# The canonical card name of this card
var card_name: String
# We will look for this card property to determine how many possible
# copies of the card are allowed in the deck. A value of 0 (or undefined)
# Will allow as many copies as the max_quantity
export var quantity_property: String = "_max_allowed"


onready var _card_label:= $CardLabel
onready var _plus_button := $Quantity/Plus
onready var _minus_button := $Quantity/Minus
onready var _quantity_edit := $Quantity/IntegerLineEdit
# Links to the various quantity buttons in a way that can be easily iterated.
onready var _qbuttons = {
	0: $'Quantity/0',
	1: $'Quantity/1',
	2: $'Quantity/2',
	3: $'Quantity/3',
	4: $'Quantity/4',
	5: $'Quantity/5',
}

func _ready() -> void:
	for quantity_button in _qbuttons:
		_qbuttons[quantity_button].connect("quantity_set", self, "_on_quantity_set")
	_quantity_edit.minimum = 0
	_quantity_edit.connect("int_entered", self, "set_quantity")


# Setter for quantity
#
# Will also set the correct button as pressed when the quantity is changed
# elsewhere.
func set_quantity(value) -> void:
	if value < 0:
		value = 0
	quantity = value
	if value > max_allowed:
		return
	for button in _qbuttons:
		if button == value:
			_qbuttons[button].pressed = true
		else:
			_qbuttons[button].pressed = false
	if value:
		_quantity_edit.text = str(value)
	else:
		_quantity_edit.text = ''
	if value > 0:
		# If the DeckCardObject doesn't exist, we create it
		# then connect it to ourselves.  This way when the user modifies the
		# values from it, it goes through the functions here always.
		if not deck_card_object:
			deck_card_object = deckbuilder.add_new_card(
					card_name,
					card_properties[CardConfig.SCENE_PROPERTY],
					value)
			deck_card_object.connect("quantity_changed",self,"_on_quantity_set")
		else:
			deck_card_object.set_quantity(value)
	elif value == 0:
		if deck_card_object:
			deck_card_object.queue_free()
			deck_card_object = null


# This is used to prepare the values of this object
func setup(_card_name: String, count = 0) -> void:
	card_properties = cfc.card_definitions[_card_name].duplicate()
	card_name = _card_name
	$Type.text = card_properties[CardConfig.SCENE_PROPERTY]
	_card_label.text = card_name
	setup_max_quantity()
	set_quantity(count)


# Sets the max amount of this card allowe in a deck
# This can be adjusted from the card properties, or from the deckbuilder
# exported variables.
#
# If less than 6 cards are allowed in the deck, then we provide the users
# dedicated buttons, to quickly adjust their values
#
# If 6 or more cards of the same name are allowed in the deck, then we provide
# the users with +/- buttons and a freeform integer line editor.
func setup_max_quantity() -> void:
	if card_properties.get("_max_allowed",0):
		 max_allowed = card_properties.get("_max_allowed")
	_quantity_edit.maximum = max_allowed
	_quantity_edit.placeholder_text = \
			"Max " + str(max_allowed)
	if max_allowed <= 5:
		for iter in range(1,max_allowed+1):
			_qbuttons[iter].visible = true
	else:
		_plus_button.visible = true
		_minus_button.visible = true
		_quantity_edit.visible = true


# Triggered when a QuantityButton changes the quantity
func _on_quantity_set(value: int) -> void:
	set_quantity(value)


# Increases the quantity by 1
func _on_Plus_pressed() -> void:
	set_quantity(quantity + 1)


# Decreases the quantity by 1
func _on_Minus_pressed() -> void:
	set_quantity(quantity - 1)
