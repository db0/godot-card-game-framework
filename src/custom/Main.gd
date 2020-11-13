extends Node2D

# This array holds all the previously focused cards.
var previously_focused_cards := []
# This var hold the currently focused card duplicate.
var current_focus_source : Card = null
# This ductionary holds the source origin for each dupe.
# We use this during cleanup
var dupes_dict := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func focus_card(card: Card):
	# This is responsible for showing the card closeup in the Focus viewport
	# We check if we're already focused on this card, to avoid making duplicates the whole time
	if not current_focus_source:
		# We make a duplicate of the card to display and add it on its own in our viewport world
		# This way we can standardize its scale and look and not worry about what happens on the table.
		var dupe_focus = card.duplicate()
		current_focus_source = card
		dupes_dict[dupe_focus] = card
		# We hide the manipulation buttons if the card was cloned with them visible
		dupe_focus.get_node('Control/ManipulationButtons').modulate[3] = 0
		# We store all our previously focused cards in an array, and clean them up process when they're not focused anymore
		previously_focused_cards.append(dupe_focus)
		$Focus/Viewport.add_child(dupe_focus)
		# We scale it up to allow the player a better viewing experience
		dupe_focus.scale = Vector2(1.5,1.5)
		# We make the viewport camera focus on it
		$Focus/Viewport/Camera2D.position = dupe_focus.global_position
		# We do a nice alpha-modulate tween
		$Focus/Tween.remove_all() # We always make sure to clean tweening conflicts
		$Focus/Tween.interpolate_property($Focus,'modulate',
		$Focus.modulate, Color(1,1,1,1), 0.25,
		Tween.TRANS_SINE, Tween.EASE_IN)
		$Focus/Tween.start()

func unfocus(card: Card):
	# This is responsible for hiding the focus viewport when we're done looking at it
	if current_focus_source == card:
		current_focus_source = null
		$Focus/Tween.remove_all() # We always make sure to clean tweening conflicts
		$Focus/Tween.interpolate_property($Focus,'modulate',
		$Focus.modulate, Color(1,1,1,0), 0.25,
		Tween.TRANS_SINE, Tween.EASE_IN)
		$Focus/Tween.start()


func _process(_delta):
	# The below makes sure to display the closeup of the card, only on the side the player's mouse is not in.
	if get_global_mouse_position().x < get_viewport().size.x/2:
		$Focus.rect_position.x = get_viewport().size.x - $Focus.rect_size.x
	else:
		$Focus.rect_position.x = 0
	# The below performs some garbage collection on previously focused cards.
	for c in previously_focused_cards:
		# We only delete old dupes if there's no tweening currently ongoing.
		# This is to allow the fade-to-alpha to complete nicely when we unfocus a card.
		# It does create a small glitch when quickly changing card focus. Haven't found a good way to avoid it yet
		if current_focus_source != dupes_dict[c] and not $Focus/Tween.is_active():
			previously_focused_cards.erase(c)
			c.queue_free()
