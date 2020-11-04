extends Node2D
# Code for a sample playspace, you're expected to provide your own ;)

var allCards := [] # A pseudo-deck array to hold the card objects we want to pull
const cardTemplate = preload("res://CardTemplate.tscn")
var UT := false # Unit Testing flag
var UT_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_current_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_target_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_mouse_speed := 3 # Simulated mouse movement speed for Unit Testing. The bigger the number, the faster the mouse moves
var t = 0 # Used for interpolating

# Called when the node enters the scene tree for the first time.
func _ready():
	#print(get_parent().name)
	# We're assigning our positions programmatically, instead of defining them on the scene.
	# This way any they will work with any size of viewport in a game.
	# Discard pile goes bottom right
	$DiscardPile.position = Vector2(get_viewport().size.x - $DiscardPile/Control.rect_size.x,get_viewport().size.y - $DiscardPile/Control.rect_size.y)
	# Deck goes bottom left
	$Deck.position = Vector2(0,get_viewport().size.y - $Deck/Control.rect_size.y)
	# Fill up the deck for demo purposes
	for _i in range(20):
		var card: Card = cardTemplate.instance()
		$Deck.add_child(card)
		allCards.append(card) # Just keeping track of all the instanced card objects for demo purposes
		card.rect_global_position = $Deck.position
		card.visible = false # This needs to start false, otherwise the card children will be drawn on-top of the deck
		card.modulate.a = 0 # We use this for a nice transition effect

func UT_interpolate_mouse_move(newpos: Vector2, startpos := Vector2(-1,-1), mouseSpeed := 3) -> void:
	# This function is called by our unit testing to simulate mouse movement on the board
	if startpos == Vector2(-1,-1):
		UT_current_mouse_position = UT_mouse_position
	else:
		UT_current_mouse_position = startpos
	UT_mouse_speed = mouseSpeed
	UT_target_mouse_position = newpos

func _physics_process(delta):
	if UT_mouse_position != UT_target_mouse_position:
		t += delta * 3
		UT_mouse_position = UT_current_mouse_position.linear_interpolate(UT_target_mouse_position, t)
	else:
		t = 0

func _on_FancyMovementToggle_toggled(_button_pressed):
	# This function is to avoid relating the logic in the card objects to a node which might not be there in another game
	# You can remove this function and the FancyMovementToggle button without issues
	cfc_config.fancy_movement = $FancyMovementToggle.pressed

func _on_ReshuffleAll_pressed():
	for c in allCards:
		if c.get_parent() != cfc_config.NMAP.deck:
			c.reHost(cfc_config.NMAP.deck)
			yield(get_tree().create_timer(0.1), "timeout")
