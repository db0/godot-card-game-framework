# The CardContainer is meant to have [Card] objects as children nodes
# and arrange their indexing and visibility
class_name CardContainer
extends Area2D

# Cache control button
var all_manipulation_buttons := [] setget ,get_all_manipulation_buttons

# The various automatic placements possible on a card
# None means the container will not be adjusted as the viewport changes
# All other options will automatically adjust themselves.
enum Placements{
	NONE
	TOP_RIGHT
	TOP_MIDDLE
	TOP_LEFT
	RIGHT_MIDDLE
	LEFT_MIDDLE
	BOTTOM_RIGHT
	BOTTOM_MIDDLE
	BOTTOM_LEFT
}

# This variable spefifies the position of the card on the game layout
# This position will be retained as the window is resized.
export(Placements) var placement

# ManipulationButtons node
onready var manipulation_buttons := $Control/ManipulationButtons
# ManipulationButtons tween node
onready var manipulation_buttons_tween := $Control/ManipulationButtons/Tween
# Control node
onready var control := $Control
# Shuffle button
onready var shuffle_button := $Control/ManipulationButtons/Shuffle
onready var highlight := $Control/Highlight


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_ui()
	_init_signal()



# Initialize some of the controls to ensure
# that they are in the expected state
func _init_ui() -> void:
	for button in get_all_manipulation_buttons():
		button.modulate[3] = 0


# Registers signals for this node
func _init_signal() -> void:
	# warning-ignore:return_value_discarded
	control.connect("mouse_entered", self, "_on_Control_mouse_entered")
	# warning-ignore:return_value_discarded
	control.connect("mouse_exited", self, "_on_Control_mouse_exited")
	# warning-ignore:return_value_discarded
	for button in all_manipulation_buttons:
		button.connect("mouse_entered", self, "_on_button_mouse_entered")
		#button.connect("mouse_exited", self, "_on_button_mouse_exited")
	shuffle_button.connect("pressed", self, '_on_Shuffle_Button_pressed')
	get_viewport().connect("size_changed",self,"_on_viewport_resized")

# Hides the container manipulation buttons when you stop hovering over them
func _on_Control_mouse_exited() -> void:
	# We always make sure to clean tweening conflicts
	hide_buttons()


# Shows the container manipulation buttons when the player hovers over them
func _on_Control_mouse_entered() -> void:
	# We always make sure to clean tweening conflicts
	show_buttons()


# Ensures the buttons are visible on hover
# Ensures that buttons are not trying to disappear via previous animation
func _on_button_mouse_entered() -> void:
	# We stop ongoing animations to avoid conflicts.
	manipulation_buttons_tween.remove_all()
	for button in all_manipulation_buttons:
		button.modulate[3] = 1


# Triggers pile shuffling
func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	shuffle_cards()


# Hides manipulation buttons
func hide_buttons() -> void:
	# We stop existing tweens to avoid deadlocks
	manipulation_buttons_tween.remove_all()
	for button in all_manipulation_buttons:
		manipulation_buttons_tween.interpolate_property(button, 'modulate:a',
				button.modulate.a, 0, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()


# Shows manipulation buttons
func show_buttons() -> void:
	manipulation_buttons_tween.remove_all()
	for button in all_manipulation_buttons:
		manipulation_buttons_tween.interpolate_property(button, 'modulate:a',
				button.modulate.a, 1, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()


# Getter for all_manipulation_buttons
#
# Updates Array with all manipulation_button group nodes,
# By using group, different tree structures are allowed
func get_all_manipulation_buttons() -> Array:
	var buttons = get_tree().get_nodes_in_group("manipulation_button")
	all_manipulation_buttons.clear()
	for button in buttons:
		if is_a_parent_of(button):
			all_manipulation_buttons.append(button)
	return all_manipulation_buttons


# Overrides the built-in get_class to return "CardContainer" instead of "Area2D"
func get_class():
	return "CardContainer"


# Returns an array with all children nodes which are of Card class
func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		# We want dragged cards to not be taken into account
		# when reorganizing the hand (so that their gap closes immediately)
		if obj as Card and obj != cfc.card_drag_ongoing:
			cardsArray.append(obj)
	return cardsArray


# Returns an int with the amount of children nodes which are of Card class
func get_card_count() -> int:
	return len(get_all_cards())


# Returns a card object of the card in the specified index among all cards.
func get_card(idx: int) -> Card:
	return get_all_cards()[idx]


# Returns an int of the index of the card object requested
func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)


# Returns a random card object among the children nodes
func get_random_card() -> Card:
	if get_card_count() == 0:
		return null
	else:
		var cardsArray := get_all_cards()
		return cardsArray[CFUtils.randi() % len(cardsArray)]


# Return the card with the lowest index
func get_last_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "top" card in the pile
		# is the last node in the node hierarchy, so
		# to retrieve the last card placed, we choose the last index
		card = get_all_cards().back()
	return card # Returning the card object for unit testing


# Teturn the card with the highest index
func get_first_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "bottom" card in the pile
		# as it appears on screen, is the first node in the node hierarchy, so
		# to retrieve the last c
		card = get_card(0)
	return card # Returning the card object for unit testing


# Randomly rearranges the order of the Card nodes.
func shuffle_cards() -> void:
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	CFUtils.shuffle_array(cardsArray)
	for card in cardsArray:
		move_child(card, cardsArray.find(card))


# Translates requested card index to true node index.
# By that, we mean the index the Card object it would have among all its
# siblings, inlcuding non-Card nodes
func translate_card_index_to_node_index(index: int) -> int:
	var node_index := 0
	# To figure out the index, we use the existing cards
	var all_cards := get_all_cards()
	# First we check if the requested index is higher than the amount of cards
	# If so, we give back the next available index
	if index > len(all_cards):
		node_index = len(all_cards)
		print("WARNING: Higher card index than hosted cards requested on "
				+ name + ". Returning max position:" + str(node_index))
	else:
		# If the requester index is not higher than the number of cards
		# We figure out which card has the index at the moment, and return
		# its node index
		var card_at_index = all_cards[index]
		node_index = card_at_index.get_index()
	return node_index


# Adjusts the placement of the node, according to the placement var
# So that it always stays in the same approximate location
func re_place():
		var place: Vector2
		match placement:
			Placements.TOP_RIGHT, Placements.RIGHT_MIDDLE, Placements.BOTTOM_RIGHT:
				place.x = get_viewport().size.x - $Control.rect_size.x
				add_to_group("right")
			Placements.TOP_LEFT, Placements.LEFT_MIDDLE, Placements.BOTTOM_LEFT:
				place.x = 0
				add_to_group("left")
			Placements.TOP_MIDDLE, Placements.BOTTOM_MIDDLE:
				place.x = get_viewport().size.x / 2 - $Control.rect_size.x / 2
		match placement:
			Placements.TOP_LEFT, Placements.TOP_MIDDLE, Placements.TOP_RIGHT:
				place.y = 0
				add_to_group("top")
			Placements.BOTTOM_LEFT, Placements.BOTTOM_MIDDLE, Placements.BOTTOM_RIGHT:
				place.y = get_viewport().size.y - $Control.rect_size.y
				add_to_group("bottom")
			Placements.RIGHT_MIDDLE, Placements.LEFT_MIDDLE:
				place.y = get_viewport().size.y / 2 - $Control.rect_size.y / 2
#		if name == "Deck":
#			print('view: ', get_viewport().size.y, ' size: ',$Control.rect_size,' pos: ',position,' place: ', place)
		position = place


func _on_viewport_resized() -> void:
	if ProjectSettings.get("display/window/stretch/mode") == "disabled":
		re_place()
