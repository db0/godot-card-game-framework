extends Node2D

# This array holds all the previously focused cards.
var previously_focused_cards := []
# This var hold the currently focused card duplicate.
var card_focus = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func focus_card(card: Card):
	# This is responsible for showing the card closeup in the Focus viewport
	# We make a duplicate of the card to display and add it on its own in our viewport world
	# This way we can standardize its scale and look and not worry about what happens on the table.
	card_focus = card.duplicate()
	# We store all our previously focused cards in an array, and clean them up process when they're not focused anymore
	previously_focused_cards.append(card_focus)
	$Focus/Viewport.add_child(card_focus)
	# We scale it up to allow the player a better viewing experience
	card_focus.scale = Vector2(1.5,1.5)
	# We make the viewport camera focus on it
	$Focus/Viewport/Camera2D.position = card_focus.global_position 
	# We do a nice alpha-modulate tween
	$Focus/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Focus/Tween.interpolate_property($Focus,'modulate',
	$Focus.modulate, Color(1,1,1,1), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Focus/Tween.start()

func unfocus():
	# This is responsible for cleaning upthe card closeup on the Focus viewport
	$Focus/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Focus/Tween.interpolate_property($Focus,'modulate',
	$Focus.modulate, Color(1,1,1,0), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Focus/Tween.start()
	yield($Focus/Tween, "tween_all_completed")
	# Once the tween is completed,we make sure we cleanup all cards
	card_focus = null


func _process(_delta):
	# The below makes sure to display the closeup of the card, only on the side the player's mouse is not in.
	if get_global_mouse_position().x < get_viewport().size.x/2:
		$Focus.rect_position.x = get_viewport().size.x - $Focus.rect_size.x
	else:
		$Focus.rect_position.x = 0
	# The below performs some garbage collection on previously focused cards.
	for c in previously_focused_cards:
		if c != card_focus:
			previously_focused_cards.erase(c)
			c.queue_free()
