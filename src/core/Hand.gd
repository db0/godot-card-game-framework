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


# Visibly shuffles all cards in hand
func shuffle_cards() -> void:
	# When shuffling the hand, we also want to show the player
	# So execute the parent function, then call each card to reorg itself
	.shuffle_cards()
	for card in get_all_cards():
		card.interruptTweening()
		card.reorganizeSelf()
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
