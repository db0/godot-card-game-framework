extends Node2D
# Code for a sample playspace, you're expected to provide your own ;)

var allCards := [] # A pseudo-deck array to hold the card objects we want to pull
const cardTemplate = preload("res://CardTemplate.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	# We're assigning our positions programmatically, instead of defining them on the scene.
	# This way any they will work with any size of viewport in a game.
	# Discard pile goes bottom right
	$DiscardPile.rect_position = Vector2(get_viewport().size.x - $DiscardPile.rect_size.x,get_viewport().size.y - $DiscardPile.rect_size.y)
	# Deck goes bottom left
	$Deck.rect_position = Vector2(0,get_viewport().size.y - $Deck.rect_size.y)
	#$Deck.rect_position = Vector2(0,0) # Debug
	# Fill up the deck for demo purposes
	for _i in range(20):
		var card: Card = cardTemplate.instance()
		$Deck/Cards.add_child(card)
		allCards.append(card) # Just keeping track of all the instanced card objects for demo purposes
		card.rect_global_position = $Deck.rect_position
		card.visible = false # This needs to start false, otherwise the card children will be drawn on-top of the deck
		card.modulate.a = 0 # We use this for a nice transition effect


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_FancyMovementToggle_toggled(_button_pressed):
	# This function is to avoid relating the logic in the card objects to a node which might not be there in another game
	# You can remove this function and the FancyMovementToggle button without issues
	for c in allCards:
		c.fancy_movement_setting = $FancyMovementToggle.pressed


func _on_ReshuffleAll_pressed():
	for c in allCards:
		if c.fancy_movement:
			c.fancy_movement = false # I can't get the fancy movement to look good on returning to the deck :'(
		c.reHost($Deck/Cards)
