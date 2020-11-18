# The CardContainer is meant to have Card objects as children
# and arrange their indexing and visibility
class_name CardContainer
extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_entered",self,"_on_Control_mouse_entered")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_exited",self,"_on_Control_mouse_exited")
	# warning-ignore:return_value_discarded
	for button in $Control/ManipulationButtons.get_children():
		if button.name != "Tween":
			button.connect("mouse_entered",self,"_on_button_mouse_entered")
			button.connect("mouse_exited",self,"_on_button_mouse_exited")
	$Control/ManipulationButtons/Shuffle.connect(
				"pressed",self,'_on_Shuffle_Button_pressed')


# Shows the container manipulation buttons when the player hovers over them
func _on_Control_mouse_entered() -> void:
	 # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons/Tween.interpolate_property(
			$Control/ManipulationButtons,'modulate',
			$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
			Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()


# Hides the container manipulation buttons when you stop hovering over them
func _on_Control_mouse_exited() -> void:
	# We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons/Tween.interpolate_property(
			$Control/ManipulationButtons,'modulate',
			$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
			Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()


# Ensures the mouse is visible on hover
# Ensures that button it not trying to  disappear via previous animation
func _on_button_mouse_entered() -> void:
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 1


# Ensures the mouse is invisible on hover
# Ensures that button it not trying to appear via previous animation
func _on_button_mouse_exited() -> void:
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 0


# Triggers pile shuffling
func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	shuffle_cards()


# Overrides the built-in get_class to return "CardContainer" instead of "Area2D"
func get_class(): return "CardContainer"


# Returns an array with all children nodes which are of Card class
func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		# This comparison will return null if obj is not a Card class.
		if obj as Card:
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
	var cardsArray := get_all_cards()
	randomize()
	return cardsArray[randi()%len(cardsArray)]


# Randomly rearranges the order of the Card nodes.
func shuffle_cards() -> void:
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	randomize()
	cardsArray.shuffle()
	for card in cardsArray:
		move_child(card,cardsArray.find(card))


# Translates requested card index to true node index.
# By that, we mean the index the Card object it would have among all its
# siblings, inlcuding non-Card nodes
func translate_card_index_to_node_index(index: int) -> int:
	var node_index := 0
	# To figure out the index, we use the existing cards
	var all_cards := get_all_cards()
	# First we check if the requested index is higher than the amount of cards
	# If so, we give back the next available index
	if index >= len(all_cards):
		node_index = len(get_child_count())
		print("WARNING: Higher card index than hosted cards requested. Returning last position.")
	else:
		# If the requester index is not higher than the number of cards
		# We figure out which card has the index at the moment, and return
		# its node index
		var card_at_index = all_cards[index]
		node_index = card_at_index.get_index()
	return(node_index)
