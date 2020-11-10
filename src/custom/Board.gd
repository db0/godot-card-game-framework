extends Board

# Code for a sample playspace, you're expected to provide your own ;)

var allCards := [] # A pseudo-deck array to hold the card objects we want to pull
const cardTemplate = preload("res://src/core/CardTemplate.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# We're assigning our positions programmatically, instead of defining them on the scene.
	# This way any they will work with any size of viewport in a game.
	# Discard pile goes bottom right
	$DiscardPile.position = Vector2(get_viewport().size.x - $DiscardPile/Control.rect_size.x,get_viewport().size.y - $DiscardPile/Control.rect_size.y)
	# Deck goes bottom left
	$Deck.position = Vector2(0,get_viewport().size.y - $Deck/Control.rect_size.y)
	# Hand goes in the middle of the two
	$Hand.position = Vector2(150,get_viewport().size.y - $Hand/Control.rect_size.y + $Hand.bottom_margin)
	$FancyMovementToggle.pressed = cfc_config.fancy_movement
	$ScalingFocusOptions.selected = cfc_config.focus_style
	# Fill up the deck for demo purposes
	if not get_tree().get_root().has_node('Gut'):
		load_test_cards()
	
func load_test_cards():
	for _i in range(15):
		var card: Card = cardTemplate.instance()
		$Deck.add_child(card)
		card._determine_idle_state()
		allCards.append(card) # Just keeping track of all the instanced card objects for demo purposes
		card.position = Vector2(0,0)
		card.modulate.a = 0 # We use this for a nice transition effect	

func _on_FancyMovementToggle_toggled(_button_pressed):
	# This function is to avoid relating the logic in the card objects to a node which might not be there in another game
	# You can remove this function and the FancyMovementToggle button without issues
	cfc_config.fancy_movement = $FancyMovementToggle.pressed

func _on_ReshuffleAll_pressed():
	for c in allCards:
		if c.get_parent() != cfc_config.NMAP.deck:
			c.reHost(cfc_config.NMAP.deck)
			yield(get_tree().create_timer(0.1), "timeout")

func _on_ScalingFocusOptions_item_selected(index):
	cfc_config.focus_style = index
