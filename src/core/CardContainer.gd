class_name CardContainer
extends Area2D


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
	$Control/ManipulationButtons/Shuffle.connect("pressed",self,'_on_Shuffle_Button_pressed')


func _on_Control_mouse_entered() -> void:
	# This function shows the container manipulation buttons when you hover over them
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()


func _on_Control_mouse_exited() -> void:
	# This function hides the container manipulation buttons when you stop hovering over them
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()


func _on_button_mouse_entered() -> void:
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 1


func _on_button_mouse_exited():
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 0


func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	shuffle_cards()


func get_class(): return "CardContainer"


func get_all_cards() -> Array:
	# This function will return an array with all the hosted Card objects in this node.
	var cardsArray := []
	for obj in get_children():
		# This comparison will return null if obj is not a Card class.
		if obj as Card:
			cardsArray.append(obj)
	return cardsArray


func get_card_count() -> int:
	return len(get_all_cards())


func get_card(idx: int) -> Card:
	return get_all_cards()[idx]


func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)


func get_random_card() -> Card:
	var cardsArray := get_all_cards()
	randomize()
	return cardsArray[randi()%len(cardsArray)]


func shuffle_cards() -> void:
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	randomize()
	cardsArray.shuffle()
	for card in cardsArray:
		move_child(card,cardsArray.find(card))


func translate_card_index_to_node_index(index: int) -> int:
	# This function is responsible for translating requested card index to true node index.
	# I.e the index it would have among all its existing children, inlcuding non-Card nodes
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
		# We figure out which card has the index at the moment, and return its node index
		var card_at_index = all_cards[index]
		node_index = card_at_index.get_index()
	return(node_index)
