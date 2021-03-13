# This class is meant to serve as your main scene for your card game
# In that case, it will enable the game to use hovering viewports
# For displaying card information
class_name ViewportCardFocus
extends Node2D

export(PackedScene) var board_scene : PackedScene
export(PackedScene) var info_panel_scene : PackedScene
# This array holds all the previously focused cards.
var _previously_focused_cards := []
# This var hold the currently focused card duplicate.
var _current_focus_source : Card = null
# This ductionary holds the source origin for each dupe.
# We use this during cleanup
var _dupes_dict := {}

onready var card_focus := $VBC/Focus
onready var focus_info := $VBC/FocusInfo


# Called when the node enters the scene tree for the first time.
func _ready():
	cfc.map_node(self)
	# We use the below while to wait until all the nodes we need have been mapped
	# "hand" should be one of them.
	$ViewportContainer/Viewport.add_child(board_scene.instance())
	if not cfc.are_all_nodes_mapped:
		yield(cfc, "all_nodes_mapped")
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed",self,"_on_Viewport_size_changed")
	$ViewportContainer.rect_size = get_viewport().size
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	focus_info.info_panel_scene = info_panel_scene
	focus_info.setup()


func _process(_delta) -> void:
	# The below makes sure to display the closeup of the card, only on the side
	# the player's mouse is not in.
	if get_global_mouse_position().x < get_viewport().size.x/2:
		$VBC.rect_position.x = get_viewport().size.x - $VBC.rect_size.x
	else:
		$VBC.rect_position.x = 0
	# The below performs some garbage collection on previously focused cards.
	for c in _previously_focused_cards:
		# We only delete old dupes if there's no tweening currently ongoing.
		# This is to allow the fade-to-alpha to complete nicely when we
		# unfocus a card.
		# It does create a small glitch when quickly changing card focus.
		# Haven't found a good way to avoid it yet
		if _current_focus_source != _dupes_dict[c]\
				and not $VBC/Focus/Tween.is_active():
			_previously_focused_cards.erase(c)
			c.queue_free()
	# This ensures that quickly unfocusing and refocusing the same card
	# Doesn't leave leftover objects.
	if _previously_focused_cards.size() > 1:
		for c in _previously_focused_cards:
			_previously_focused_cards.erase(c)
			c.queue_free()
			if _previously_focused_cards.size() == 1:
				break

# Takes care to resize the child viewport, when the main viewport is resized
func _on_Viewport_size_changed() -> void:
	if ProjectSettings.get("display/window/stretch/mode") == "disabled":
		$ViewportContainer.rect_size = get_viewport().size


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
		dupe_focus.remove_from_group("cards")
		_current_focus_source = card
		_dupes_dict[dupe_focus] = card
		_extra_dupe_preparation(dupe_focus, card)
		# We display a "pure" version of the card
		# This means we hide buttons, tokens etc
		dupe_focus.state = Card.CardState.VIEWPORT_FOCUS
		for c in _previously_focused_cards:
			c.visible = false
		# We store all our previously focused cards in an array, and clean them
		# up when they're not focused anymore
		_previously_focused_cards.append(dupe_focus)
		$VBC/Focus/Viewport.add_child(dupe_focus)
		_extra_dupe_ready(dupe_focus, card)
		# We have to copy these internal vars because they are reset
		# see https://github.com/godotengine/godot/issues/3393
		dupe_focus.is_faceup = card.is_faceup
		dupe_focus.is_viewed = card.is_viewed
		# We make the viewport camera focus on it
		$VBC/Focus/Viewport/Camera2D.position = dupe_focus.global_position
		# We always make sure to clean tweening conflicts
		$VBC/Focus/Tween.remove_all()
		# We do a nice alpha-modulate tween
		$VBC/Focus/Tween.interpolate_property($VBC/Focus,'modulate',
				$VBC/Focus.modulate, Color(1,1,1,1), 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
		if focus_info.visible_details > 0:
			$VBC/Focus/Tween.interpolate_property(focus_info,'modulate',
					focus_info.modulate, Color(1,1,1,1), 0.25,
					Tween.TRANS_SINE, Tween.EASE_IN)
		else:
			$VBC/Focus/Tween.interpolate_property(focus_info,'modulate',
					focus_info.modulate, Color(1,1,1,0), 0.25,
					Tween.TRANS_SINE, Tween.EASE_IN)
		$VBC/Focus/Tween.start()


# Hides the focus viewport when we're done looking at it
func unfocus(card: Card) -> void:
	if _current_focus_source == card:
		_current_focus_source = null
		$VBC/Focus/Tween.remove_all()
		$VBC/Focus/Tween.interpolate_property($VBC/Focus,'modulate',
				$VBC/Focus.modulate, Color(1,1,1,0), 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
		if focus_info.modulate != Color(1,1,1,0):
			$VBC/Focus/Tween.interpolate_property(focus_info,'modulate',
					focus_info.modulate, Color(1,1,1,0), 0.25,
					Tween.TRANS_SINE, Tween.EASE_IN)
		$VBC/Focus/Tween.start()


# Overridable function for games to extend preprocessing of dupe card
# before adding it to the scene
func _extra_dupe_preparation(dupe_focus: Card, card: Card) -> void:
	dupe_focus.canonical_name = card.canonical_name
	dupe_focus.properties = card.properties.duplicate()
	focus_info.hide_all_info()
	cfc.ov_utils.populate_info_panels(card,focus_info)


# Overridable function for games to extend processing of dupe card
# after adding it to the scene
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _extra_dupe_ready(dupe_focus: Card, card: Card) -> void:
	pass
