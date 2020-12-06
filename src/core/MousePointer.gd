# This handles the mouse pointer collision shape 2D interactions
# It is used for detecting when a card and its elements is being hovered
# As we cannot rely on Control node relevant signals due to Godot bugs
# such as:
# * https://github.com/godotengine/godot/issues/16854
# * https://github.com/godotengine/godot/issues/44138
class_name MousePointer
extends Area2D

# The card that is currently highlighted as a result of this
# mouse cursor hovering over it.
var current_focused_card : Card = null
# The amount of cards the cursor is hovering. We're using our own
# Array instead of get_overlapping_areas() because those are updated
# every tick, which causes glitches when the player moves the mouse too fast.
#
# Instead we populate according to signals,which are more immediate
var overlaps := []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("area_entered",self,"_on_MousePointer_area_entered")
	connect("area_exited",self,"_on_MousePointer_area_exited")
	if cfc.debug:
		$DebugShape.visible = true


func _process(_delta: float) -> void:
	if current_focused_card:
		# We after a card has been dragged, it generally clears its
		# focused state. This check ensures that if the mouse hovers over
		# the card still after the drag, we focus it again
		if current_focused_card.get_parent() == cfc.NMAP.board \
				and current_focused_card.state == Card.ON_PLAY_BOARD:
			current_focused_card.state = Card.FOCUSED_ON_BOARD
		if current_focused_card.get_parent() == cfc.NMAP.hand \
				and current_focused_card.state == Card.IN_HAND:
			current_focused_card.state = Card.FOCUSED_IN_HAND
		if cfc.card_drag_ongoing and cfc.card_drag_ongoing != current_focused_card:
			current_focused_card = cfc.card_drag_ongoing
	if cfc.debug:
		$DebugShape/current_focused_card.text = "MOUSE: " + str(current_focused_card)

func _on_MousePointer_area_entered(area: Area2D) -> void:
	overlaps.append(area)
	#print("enter:",area)
	_discover_focus()


func _on_MousePointer_area_exited(area: Area2D) -> void:
	overlaps.erase(area)
	#print("exit:",area)
	_discover_focus()




# We're using this helper function, to allow our mouse-position relevant code
# to work during integration testing
# Returns either the adjusted global mouse position
# or a fake mouse position provided by integration testing
func determine_global_mouse_pos() -> Vector2:
	var mouse_position
	var zoom = Vector2(1,1)
	# We have to do the below offset hack due to godotengine/godot#30215
	# This is caused because we're using a viewport node and
	# scaling the game in full-creen.
	if get_viewport() and get_viewport().has_node("Camera2D"):
		zoom = get_viewport().get_node("Camera2D").zoom
	var offset_mouse_position = \
			get_tree().current_scene.get_global_mouse_position() \
			- get_viewport_transform().origin
	offset_mouse_position *= zoom
	#var scaling_offset = get_tree().get_root().get_node('Main').get_viewport().get_size_override() * OS.window_size
	if cfc.UT: mouse_position = cfc.NMAP.board._UT_mouse_position
	else: mouse_position = offset_mouse_position
	return mouse_position


# Parses all collided objects and figures out which card, if any, to focus on.
func _discover_focus() -> void:
	var potential_cards := []
	# We might overlap cards or their token drawers, but we hihglight
	# only cards.
	for c in overlaps:
		if c as Card:
			potential_cards.append(c)
	if not potential_cards.empty():
		# We sort the potential cards by their index on the board
		potential_cards.sort_custom(CardFrameworkUtils,"sort_index_ascending")
		# The candidate always has the highest index as it's drawn on top of
		# others.
		var card : Card = potential_cards.back()
		# if this card was not already focused...
		if current_focused_card != card:
			# We don't want to change focus while we're either dragging
			# a card around, or we're hovering over a previously
			# focused card's token drawer.
			if not (current_focused_card
					and current_focused_card.state == Card.DRAGGED) \
				and not (current_focused_card
					and current_focused_card._is_drawer_hovered()
					and current_focused_card._is_drawer_open):
				# If we already highlighted a card that is lower in index
				# we remove it's focus state
				if current_focused_card:
					current_focused_card._on_Card_mouse_exited()
				card._on_Card_mouse_entered()
				current_focused_card = card
	# If we don't collide with any objects, but we have been focusing until
	# now, we make sure we're not hovering over the card drawer.
	# if not, then we remove focus.
	#
	# Because sometimes the mouse moves faster than a dragged card,
	# We make sure we don't try to change the current_focused_card while
	# in the process of dragging one.
	elif current_focused_card and current_focused_card.state != Card.DRAGGED:
		if not current_focused_card._is_drawer_hovered() \
				or not current_focused_card._is_drawer_open:
			current_focused_card._on_Card_mouse_exited()
			current_focused_card = null
