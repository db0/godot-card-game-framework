# The CardContainer is meant to have Card objects as children
# and arrange their indexing and visibility
class_name CardContainer
extends Area2D

onready var manipulation_buttons = $Control/ManipulationButtons
onready var manipulation_buttons_tween = $Control/ManipulationButtons/Tween
onready var control = $Control
onready var shuffle = $Control/ManipulationButtons/Shuffle
onready var view = $Control/ManipulationButtons/View
var manipulation_buttons_self = []
var area_name :String  setget ,get_area_name
var shuffle_index = []
var random_seed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_ui()
	_init_signal()
	_init_data()

func _init_data():
	var cur_seed = random_seed
	if not cur_seed:
		cur_seed =  hash("godot")
	random_seed = rand_seed(cur_seed)[1]

func _init_ui() -> void:
	for button in get_manipulation_buttons():
		button.modulate[3] = 0
func _init_signal() -> void:
	# warning-ignore:return_value_discarded
	control.connect("mouse_entered",self,"_on_Control_mouse_entered")
	# warning-ignore:return_value_discarded
	control.connect("mouse_exited",self,"_on_Control_mouse_exited")
	# warning-ignore:return_value_discarded
	for button in get_manipulation_buttons():
		button.connect("mouse_entered",self,"_on_button_mouse_entered")

	shuffle.connect("pressed",self,'_on_Shuffle_Button_pressed')

func get_manipulation_buttons():
	if len(manipulation_buttons_self) == 0:
		var buttons = get_tree().get_nodes_in_group("manipulation_button")
		manipulation_buttons_self = []
		for button in buttons:
			if is_a_parent_of(button):
				manipulation_buttons_self.append(button)
	return manipulation_buttons_self

# Shows the container manipulation buttons when the player hovers over them
func _on_Control_mouse_entered() -> void:
	 # We always make sure to clean tweening conflicts
	manipulation_buttons_tween.remove_all()
	for button in get_manipulation_buttons():
		manipulation_buttons_tween.interpolate_property(
				button,'modulate:a',
				button.modulate.a, 1, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()


# Hides the container manipulation buttons when you stop hovering over them
func _on_Control_mouse_exited() -> void:
	# We always make sure to clean tweening conflicts
	manipulation_buttons_tween.remove_all()
	for button in get_manipulation_buttons():
		manipulation_buttons_tween.interpolate_property(
				button,'modulate:a',
				button.modulate.a, 0, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()

# Ensures the mouse is visible on hover
# Ensures that button it not trying to  disappear via previous animation
func _on_button_mouse_entered() -> void:
	manipulation_buttons_tween.remove_all()
	for button in get_manipulation_buttons():
		button.modulate[3] = 1

# Triggers pile shuffling
func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	shuffle_cards()


# Overrides the built-in get_class to return "CardContainer" instead of "Area2D"
func get_class(): return "CardContainer"


# Returns an array with all children nodes which are of Card class
func get_all_cards() -> Array:
	return get_tree().get_nodes_in_group(get_card_group_name())


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
	return cardsArray[randi()%len(cardsArray)]


# Randomly rearranges the order of the Card nodes.
func shuffle_cards() -> void:
	shuffle_index = range(len(get_all_cards()))
	shuffle_index.shuffle()


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
		if not shuffle_index or len(shuffle_index)==0:
			shuffle_cards()
		node_index = shuffle_index[index]
	return(node_index)

func get_area_name():
	return "base_card_container"

func get_card_group_name():
	return "%s_card" % [get_area_name()]
