extends Node2D
class_name Hand
# This is meant to be a simple container for card objects. 
# Just add a Node2D with this script as a child node anywhere you want your hand to be.

### BEGIN Behaviour Constants ###
# The maximum amount of cards allowed to draw.
var hand_size := 12
### END Behaviour Constants ###

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func draw_card(container = $'../'.deck) -> void:
		# A basic function to pull a card from out deck into our hand.
		if  get_child_count() < hand_size: # prevent from drawing more cards than are in our deck and crashing godot.
			var card = container.pop_front().instance() # pop() removes a card from its container as well.
			add_child(card)
			card.moveToPosition(Vector2(0,0),card.recalculatePosition())
			for c in get_children():
				if c != card:
					c.interruptTweening()
					c.reorganizeSelf()

func _on_Button_pressed():
	draw_card() # Replace with function body.
