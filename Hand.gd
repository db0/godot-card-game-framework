# This is meant to be a simple container for card objects.
# Just add a Node2D with this script as a child node anywhere you want your hand to be.

extends Control
class_name Hand



### BEGIN Behaviour Constants ###
# The maximum amount of cards allowed to draw.

### END Behaviour Constants ###
#var hand_rect: Vector2


var dropping_card: Card = null
var catching_card: bool = false

func _ready():
	# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "_on_mouse_entered")
	# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "_on_mouse_exited")
	#print('a',self.get_node('HostedCards'), self.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func draw_card(container = cfc_config.NMAP.deck) -> Card:
	var card: Card = null
	# A basic function to pull a card from out deck into our hand.
	if container.get_card_count() and $Hand.get_child_count() < cfc_config.hand_size: # prevent from drawing more cards than are in our deck and crashing godot.
		# We need to remove the current parent node before adding a different one
		# We simply pick the first one.
		card = container.get_card(0)
		card.reHost($Hand)
	return card # Returning the card object for unit testing

func _on_Deck_gui_input(event):
	if event.is_pressed() and event.get_button_index() == 1:
		draw_card() # Replace with function body.

func _on_dropped_card(card: Card) -> void:
	#print(card.get_index())
	# This signal will arrive before the engine knows over which control our mouse pointer is
	# Therefore we cannot set the "catcher control" with the _on_mouse_enterred() signal
	# Instead we simply set a variable for the card and wait to see if the
	# catching_card variable will also be set immediately afterwards
	# Note: This variable will be set on all  such containers, so will need to be cleared if not used. We do that in _process.
	dropping_card = card


func _process(_delta):
	# Here we check if both switches have been set, which would signify this is the container which catches the dropped card
	if dropping_card and catching_card:
		#print($Hand.name)
		dropping_card.reHost($Hand)
	else:
		# If the dropping card is not in a state 'Dragged' anymore, it means another container has picked it up already
		# So we clear our hook.
		if dropping_card and dropping_card.state != 5:  # state 5 == 'Dragged'
			dropping_card = null

func _on_mouse_entered() -> void:
	# Unfortunately the gui inputs will not be sent to this control
	# Until the card is dropped, so we will only know the mouse has enterred this container 
	# only AFTER the card_cropped signal has been sent
	# Therefore we set a switch here and then compare every frame until it's cleared
	catching_card = true
	#print(dropping_card,catching_card)
	
func _on_mouse_exited() -> void:
	catching_card = false
	#print(dropping_card,catching_card)
