# This is meant to be a simple container for card objects.
# Just add a Node2D with this script as a child node anywhere you want your hand to be.

extends CardContainer # Hands are just a container with card organization functions
class_name Hand 

onready var bottom_margin: float = $Control.rect_size.y * cfc_config.bottom_margin_multiplier

### BEGIN Behaviour Constants ###
# The maximum amount of cards allowed to draw in this hand
const hand_size := 12

### END Behaviour Constants ###
#var hand_rect: Vector2

func _ready() -> void:
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/DiscardRandom.connect("pressed",self,'_on_DiscardRandom_Button_pressed')

func _on_Shuffle_Button_pressed() -> void:
	# When shuffling the hand, we also want to show the player
	# So execute the parent function, then call each card to reorg itself
	._on_Shuffle_Button_pressed()
	for card in get_all_cards():
		card.reorganizeSelf()
	move_child($Control,0)

func draw_card(pile : Pile = cfc_config.NMAP.deck) -> Card:
	var card: Card = pile.get_top_card()
	# A basic function to pull a card from out deck into our hand.
	if get_card_count() < hand_size: # prevent from exceeding our hand size
		card.moveTo(self)
	return card # Returning the card object for unit testing

func _on_Deck_input_event(event) -> void:
	if event.is_pressed() and event.get_button_index() == 1:
		# warning-ignore:return_value_discarded
		draw_card() # Replace with function body.

func _on_DiscardRandom_Button_pressed() -> void:
	var card = get_random_card()
	card.reHost(cfc_config.NMAP.discard)
