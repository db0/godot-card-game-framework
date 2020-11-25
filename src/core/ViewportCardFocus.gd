# This class is meant to serve as your main scene for your card game
# In that case, it will enable the game to use hovering viewports
# For displaying card information
class_name ViewportCardFocus
extends Node2D

# This array holds all the previously focused cards.
var _previously_focused_cards := []
# This var hold the currently focused card duplicate.
var _current_focus_source : Card = null
# This ductionary holds the source origin for each dupe.
# We use this during cleanup
var _dupes_dict := {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(_delta) -> void:
	# The below makes sure to display the closeup of the card, only on the side
	# the player's mouse is not in.
	if get_global_mouse_position().x < get_viewport().size.x/2:
		$Focus.rect_position.x = get_viewport().size.x - $Focus.rect_size.x
	else:
		$Focus.rect_position.x = 0
	# The below performs some garbage collection on previously focused cards.
	for c in _previously_focused_cards:
		# We only delete old dupes if there's no tweening currently ongoing.
		# This is to allow the fade-to-alpha to complete nicely when we
		# unfocus a card.
		# It does create a small glitch when quickly changing card focus.
		# Haven't found a good way to avoid it yet
		if _current_focus_source != _dupes_dict[c] and not $Focus/Tween.is_active():
			_previously_focused_cards.erase(c)
			c.queue_free()


# Displays the card closeup in the Focus viewport
func focus_card(card: Card) -> void:
	# We check if we're already focused on this card, to avoid making duplicates
	# the whole time
	if not _current_focus_source:
		# We make a duplicate of the card to display and add it on its own in
		# our viewport world
		# This way we can standardize its scale and look and not worry about
		# what happens on the table.
		var dupe_focus = card.duplicate()
		_current_focus_source = card
		_dupes_dict[dupe_focus] = card
		# We display a "pure" version of the card
		# This means we hide buttons, tokens etc
		dupe_focus.get_node('Control/ManipulationButtons').modulate[3] = 0
		dupe_focus.get_node('Control').rect_rotation = 0
		dupe_focus.complete_targeting()
		dupe_focus.get_node('Control/Tokens').visible = false
		# If the card has already been been viewed while down,
		# we allow the player hovering over it to see it
		if not dupe_focus.is_faceup:
			if dupe_focus.is_viewed:
				dupe_focus._flip_card(dupe_focus.get_node("Control/Back"),
						dupe_focus.get_node("Control/Front"), true)
			else:
				# We slightly reduce the colour intensity of the dupe
				# As its enlarged state makes it glow too much
				var current_colour = dupe_focus.get_node('Control/Back').modulate
				dupe_focus.get_node('Control/Back').modulate = current_colour * 0.95
		# We store all our previously focused cards in an array, and clean them
		# up when they're not focused anymore
		_previously_focused_cards.append(dupe_focus)
		$Focus/Viewport.add_child(dupe_focus)
		# We scale it up to allow the player a better viewing experience
		dupe_focus.scale = Vector2(1.5,1.5)
		# We make the viewport camera focus on it
		$Focus/Viewport/Camera2D.position = dupe_focus.global_position
		# We always make sure to clean tweening conflicts
		$Focus/Tween.remove_all()
		# We do a nice alpha-modulate tween
		$Focus/Tween.interpolate_property($Focus,'modulate',
				$Focus.modulate, Color(1,1,1,1), 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
		$Focus/Tween.start()

# Hides the focus viewport when we're done looking at it
func unfocus(card: Card) -> void:
	if _current_focus_source == card:
		_current_focus_source = null
		$Focus/Tween.remove_all()
		$Focus/Tween.interpolate_property($Focus,'modulate',
				$Focus.modulate, Color(1,1,1,0), 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
		$Focus/Tween.start()
