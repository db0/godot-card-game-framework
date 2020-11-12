extends Area2D
class_name CardContainer

var waiting_for_card_drop: bool = false

func get_class(): return "CardContainer"

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

func _on_Control_mouse_entered():
	# This function shows the container manipulation buttons when you hover over them
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()

func _on_Control_mouse_exited():
	# This function hides the container manipulation buttons when you stop hovering over them
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()

func _on_button_mouse_entered():
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 1
func _on_button_mouse_exited():
	$Control/ManipulationButtons/Tween.remove_all()
	$Control/ManipulationButtons.modulate[3] = 0

func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	randomize()
	cardsArray.shuffle()
	for card in cardsArray:
		move_child(card,cardsArray.find(card))
