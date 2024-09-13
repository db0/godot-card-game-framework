# An object displaying a card summary in the Deckbuilder available cards area
# and providing controls to add it to the deck.
class_name DBListCardObject
extends CVListCardObject

# A potential link to the card summary in the deck itself.
# If it is null, it will be created as soon as the card is added to the deck
var deck_card_object: DBDeckCardObject
# The max quantity allowed for this particular card
var max_allowed: int

# The amount of this card selected to be added to the deck.
var quantity: int: set = set_quantity
# We will look for this card property to determine how many possible
# copies of the card are allowed in the deck. A value of 0 (or undefined)
# Will allow as many copies as the max_quantity
@export var quantity_property: String = "_max_allowed"


@onready var _plus_button := $Quantity/Plus
@onready var _minus_button := $Quantity/Minus
@onready var _quantity_edit := $Quantity/IntegerLineEdit
# Links to the various quantity buttons in a way that can be easily iterated.
@onready var _qbuttons = {
	0: $'Quantity/0',
	1: $'Quantity/1',
	2: $'Quantity/2',
	3: $'Quantity/3',
	4: $'Quantity/4',
	5: $'Quantity/5',
}

func _ready() -> void:
	for quantity_button in _qbuttons:
		_qbuttons[quantity_button].connect("quantity_set", Callable(self, "_on_quantity_set"))
	_quantity_edit.minimum = 0
	# warning-ignore:return_value_discarded
	_quantity_edit.connect("int_entered", Callable(self, "set_quantity"))


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
			_qbuttons[button].button_pressed = true
		else:
			_qbuttons[button].button_pressed = false
	if value:
		_quantity_edit.text = str(value)
	else:
		_quantity_edit.text = ''
	if value > 0:
		# If the DeckCardObject doesn't exist, we create it
		# then connect it to ourselves.  This way when the user modifies the
		# values from it, it goes through the functions here always.
		if not deck_card_object:
			deck_card_object = card_viewer.add_new_card(
					card_name,
					card_properties[CardConfig.SCENE_PROPERTY],
					value)
			# warning-ignore:return_value_discarded
			deck_card_object._card_label.preview_popup.focus_info.info_panel_scene\
					= card_viewer.info_panel_scene
			deck_card_object._card_label.preview_popup.focus_info.setup()
			deck_card_object.connect("quantity_changed", Callable(self, "_on_quantity_set"))
		else:
			deck_card_object.set_quantity(value)
	elif value == 0:
		if deck_card_object:
			deck_card_object.queue_free()
			deck_card_object = null
	if grid_card_object and value >= max_allowed:
		grid_card_object.modulate = Color(0.5,0.5,0.5)
	elif grid_card_object:
		grid_card_object.modulate = Color(1,1,1)


# Sets the max amount of this card allowe in a deck
# This can be adjusted from the card properties, or from the deckbuilder
# exported variables.
#
# If less than 6 cards are allowed in the deck, then we provide the users
# dedicated buttons, to quickly adjust their values
#
# If 6 or more cards of the same name are allowed in the deck, then we provide
# the users with +/- buttons and a freeform integer line editor.
func setup_max_quantity(force := 0) -> void:
	if force:
		max_allowed = force
	elif card_properties.get("_max_allowed",0):
		max_allowed = card_properties.get("_max_allowed")
	_quantity_edit.maximum = max_allowed
	_quantity_edit.placeholder_text = \
			"Max " + str(max_allowed)
	# We reset the visibility of all objects first.
	# This allows us to change the maximum quantity of a card
	# during runtime as well
	for n in $Quantity.get_children():
		if n.name != '0':
			n.visible = false
	# For max 1-5 cards, we use the buttons
	if max_allowed <= 5:
		for iter in range(1,max_allowed+1):
			_qbuttons[iter].visible = true
	# For max 6+ cards, we use the +/- symbol and the IntegerLineEdit
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

