# A type of [CardContainer] that stores its Card objects with full visibility
# to the player and provides methods for adding new ones and reorganizing them
class_name Hand
extends CardContainer


# The maximum amount of cards allowed to draw in this hand
const hand_size := 12

# Offsets the hand position based on the configuration
onready var bottom_margin: float = $Control.rect_size.y * CFConst.BOTTOM_MARGIN_MULTIPLIER


func _ready() -> void:
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/DiscardRandom.connect("pressed",self,'_on_DiscardRandom_Button_pressed')
	re_place()


# Button which shuffles the children [Card] objects
func _on_Shuffle_Button_pressed() -> void:
	shuffle_cards()


# Function to connect to a card draw signal
func _on_Deck_input_event(event) -> void:
	if event.is_pressed() and event.get_button_index() == 1:
		# warning-ignore:return_value_discarded
		draw_card()


# Function to connect to a card discard signal
func _on_DiscardRandom_Button_pressed() -> void:
	var card = get_random_card()
	if card:
		card.move_to(cfc.NMAP.discard)


# A wrapper for the CardContainer's get_last_card()
# which make sense for the cards' index in a hand
func get_rightmost_card() -> Card:
	return(get_last_card())


# A wrapper for the CardContainer's get_first_card()
# which make sense for the cards' index in a hand
func get_leftmost_card() -> Card:
	return(get_first_card())


# Visibly shuffles all cards in hand
func shuffle_cards() -> void:
	# When shuffling the hand, we also want to show the player
	# So execute the parent function, then call each card to reorg itself
	.shuffle_cards()
	for card in get_all_cards():
		card.interruptTweening()
		card.reorganize_self()
	move_child($Control,0)


# Takes the top card from the specified [CardContainer]
# and adds it to this node
# Returns a card object drawn
func draw_card(pile : Pile = cfc.NMAP.deck) -> Card:
	var card: Card = pile.get_top_card()
	# A basic function to pull a card from out deck into our hand.
	if card and get_card_count() < hand_size: # prevent from exceeding our hand size
		card.move_to(self)
	return card

# Overrides the re_place() function of [CardContainer] in order
# to also resize the hand rect, according to how many other
# CardContainers exist in the same row/column
func re_place() -> void:
	var others_rect_x := 0.0
	var others_rect_y := 0.0
	for group in ["top","bottom", "left", "right"]:
		if group in get_groups():
			for other in get_tree().get_nodes_in_group(group):
				if group in ["top", "bottom"] and other != self:
					others_rect_x += other.control.rect_size.x
				if group in ["left", "right"]:
					others_rect_y += other.contro.rect_size.y
	if "top" in get_groups() or "bottom" in get_groups():
		$Control.rect_size.x = get_viewport().size.x - others_rect_x
	if "left" in get_groups() or "right" in get_groups():
		$Control.rect_size.y = get_viewport().size.y - others_rect_y
	$CollisionShape2D.shape.extents = $Control.rect_size / 2
	$CollisionShape2D.position = $Control.rect_size / 2
	.re_place()
	position.y += bottom_margin
	for c in get_all_cards():
		c.reorganize_self()
