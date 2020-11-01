extends Node2D
class_name Hand
# This is meant to be a simple container for card objects.
# Just add a Node2D with this script as a child node anywhere you want your hand to be.

### BEGIN Behaviour Constants ###
# The maximum amount of cards allowed to draw.
var hand_size := 12
### END Behaviour Constants ###
var hand_rect: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func draw_card(container = $'../Deck/Cards') -> Card:
	var card: Card = null
	# A basic function to pull a card from out deck into our hand.
	if container.get_child_count() and get_child_count() < hand_size: # prevent from drawing more cards than are in our deck and crashing godot.
		# We need to remove the current parent node before adding a different one
		card = container.get_child(0)
		card.reHost(self)
		# If this node is not a defined control node with a specific dimentions, we need to define its location programmatically
		# We do this by using the card dimentions. This allows us to calculate where the hand is and where the board is.
		hand_rect = Vector2(get_viewport().size.x - card.rect_size.x * 2,card.rect_size.y/2 + 20)
	return card # Returning the card object for unit testing

func _on_Deck_gui_input(event):
	if event.is_pressed() and event.get_button_index() == 1:
		draw_card() # Replace with function body.
