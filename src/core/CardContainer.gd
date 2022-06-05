# The CardContainer is meant to have [Card] objects as children nodes
# and arrange their indexing and visibility
class_name CardContainer
extends Area2D

signal shuffle_completed

# The various automatic Anchors possible for a CardContainer
# NONE means the container will not stay anchored to the screen
# and will not adjust its position if the viewport changes.
# Use this setting if your game is not expected to use different resolutions
# or you want this CardContainer to be placed somewhere other than the
# edge of the viewport (although you could adjust that in code as well)
#
# All other options will automatically adjust the position of the
# CardContainer if the resolution changes
enum Anchors{
	NONE
	TOP_RIGHT
	TOP_MIDDLE
	TOP_LEFT
	RIGHT_MIDDLE
	LEFT_MIDDLE
	BOTTOM_RIGHT
	BOTTOM_MIDDLE
	BOTTOM_LEFT
	CONTROL
}

# Spefifies the anchor of the card on the screen layout
# This placement will be retained as the window is resized.
export(Anchors) var placement
# In case of multiple CardContainers using the same anchor placement,
# specifies whether this container should displace itself to make space
# for the others, and how.
export(CFInt.OverlapShiftDirection) var overlap_shift_direction
# In case of multiple CardContainers using the same anchor placement
# specifies which container should be displaced more.
export(CFInt.IndexShiftPriority) var index_shift_priority
export var card_size := CFConst.CARD_SIZE
# If set to false, no manipulation buttons will appear when hovering
# over this container.
export var show_manipulation_buttons := true

# Used for debugging
var _debugger_hook := false
# Stores how much this container has moved from its original anchor placement
# as a result of other containers sharing the same anchor placement
var accumulated_shift := Vector2(0,0)
# ManipulationButtons node
onready var manipulation_buttons := $Control/ManipulationButtons
# ManipulationButtons tween node
onready var manipulation_buttons_tween := $Control/ManipulationButtons/Tween
# Control node
onready var control := $Control
# Shuffle button
onready var shuffle_button := $Control/ManipulationButtons/Shuffle
# Container higlight
onready var highlight := $Control/Highlight


func _process(_delta: float) -> void:
	# Debug labels
	if cfc._debug:
		$Debug.visible = true
		$Debug/Position.text = "POSITION:  " + str(position)
		$Debug/AreaPos.text = "AREA POS: " + str($CollisionShape2D.position)
		$Debug/Size.text = "SIZE: " + str($Control.rect_size)
	else:
		$Debug.visible = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cfc.map_node(self)
	# We use the below while to wait until all the nodes we need have been mapped
	# "hand" should be one of them.
	add_to_group("card_containers")
	if not cfc.are_all_nodes_mapped:
		yield(cfc, "all_nodes_mapped")
	_init_ui()
	_init_signal()
	manipulation_buttons.visible = show_manipulation_buttons


func _init_control_size() -> void:
	var parent_control: Control = get_parent()
	if placement == Anchors.CONTROL and parent_control.size_flags_horizontal != 3:
		parent_control.rect_min_size = control.rect_size * scale
		parent_control.rect_size = control.rect_size * scale

# Initialize some of the controls to ensure
# that they are in the expected state
func _init_ui() -> void:
	for button in get_all_manipulation_buttons():
		button.modulate[3] = 0


# Registers signals for this node
func _init_signal() -> void:
	# warning-ignore:return_value_discarded
	control.connect("mouse_entered", self, "_on_Control_mouse_entered")
	# warning-ignore:return_value_discarded
	control.connect("mouse_exited", self, "_on_Control_mouse_exited")
	# warning-ignore:return_value_discarded
	for button in get_all_manipulation_buttons():
		button.connect("mouse_entered", self, "_on_button_mouse_entered")
		#button.connect("mouse_exited", self, "_on_button_mouse_exited")
	shuffle_button.connect("pressed", self, '_on_Shuffle_Button_pressed')
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed",self,"_on_viewport_resized")


# Hides the container manipulation buttons when you stop hovering over them
func _on_Control_mouse_exited() -> void:
	# We always make sure to clean tweening conflicts
	hide_buttons()


# Shows the container manipulation buttons when the player hovers over them
func _on_Control_mouse_entered() -> void:
	if not cfc.game_paused:
	# We always make sure to clean tweening conflicts
		show_buttons()


# Ensures the buttons are visible on hover
# Ensures that buttons are not trying to disappear via previous animation
func _on_button_mouse_entered() -> void:
	# We stop ongoing animations to avoid conflicts.
	manipulation_buttons_tween.remove_all()
	for button in get_all_manipulation_buttons():
		button.modulate[3] = 1


# Triggers pile shuffling
func _on_Shuffle_Button_pressed() -> void:
	# Reshuffles the cards in container
	shuffle_cards()


# Called whenever the viewport is changed so ensure all containers
# are moved to their anchor.
func _on_viewport_resized() -> void:
	if ProjectSettings.get("display/window/stretch/mode") == "disabled":
		re_place()


func are_cards_still_animating() -> bool:
	for c in get_all_cards():
		var tt : Tween = c._tween
		if tt.is_active():
			return(true)
	return(false)

# Hides manipulation buttons
func hide_buttons() -> void:
	# We stop existing tweens to avoid deadlocks
	manipulation_buttons_tween.remove_all()
	for button in get_all_manipulation_buttons():
		manipulation_buttons_tween.interpolate_property(button, 'modulate:a',
				button.modulate.a, 0, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()


# Shows manipulation buttons
func show_buttons() -> void:
	manipulation_buttons_tween.remove_all()
	for button in get_all_manipulation_buttons():
		manipulation_buttons_tween.interpolate_property(button, 'modulate:a',
				button.modulate.a, 1, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
	manipulation_buttons_tween.start()


# Getter for all_manipulation_buttons
#
# Updates Array with all manipulation_button group nodes,
# By using group, different tree structures are allowed
func get_all_manipulation_buttons() -> Array:
	var buttons = get_tree().get_nodes_in_group("manipulation_button")
	var my_buttons = []
	for button in buttons:
		if is_a_parent_of(button):
			my_buttons.append(button)
	return my_buttons


# Overrides the built-in get_class to return "CardContainer" instead of "Area2D"
func get_class():
	return "CardContainer"


# Returns an array with all children nodes which are of Card class
func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		# We want dragged cards to not be taken into account
		# when reorganizing the hand (so that their gap closes immediately)
		if not obj is Card:
			continue
		if not is_instance_valid(obj):
			continue
		if obj == cfc.card_drag_ongoing:
			continue
		cardsArray.append(obj)
	return cardsArray


# Returns an int with the amount of children nodes which are of Card class
func get_card_count() -> int:
	return(get_all_cards().size())


# Returns a card object of the card in the specified index among all cards.
func get_card(idx: int) -> Card:
	if idx < 0:
		return(null)
	return(get_all_cards()[idx])


# Returns an int of the index of the card object requested
func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)


# Returns true if this card container has a Card object matching the specified one
func has_card(card: Card) -> bool:
	if card in get_all_cards():
		return(true)
	return(false)


# Returns true is any card in this card container has a canonical_name 
# that matches the provided argument.
func has_card_name(card_name: String) -> bool:
	for card in get_all_cards():
		if card.canonical_name == card_name:
			return(true)
	return(false)


# Returns a random card object among the children nodes
func get_random_card() -> Card:
	if get_card_count() == 0:
		return null
	else:
		var cardsArray := get_all_cards()
		return cardsArray[CFUtils.randi() % len(cardsArray)]


# Return the card with the lowest index
func get_last_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "top" card in the pile
		# is the last node in the node hierarchy, so
		# to retrieve the last card placed, we choose the last index
		card = get_all_cards().back()
	return card # Returning the card object for unit testing


# Teturn the card with the highest index
func get_first_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "bottom" card in the pile
		# as it appears on screen, is the first node in the node hierarchy, so
		# to retrieve the last c
		card = get_card(0)
	return card # Returning the card object for unit testing


# Randomly rearranges the order of the Card nodes.
func shuffle_cards() -> void:
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	CFUtils.shuffle_array(cardsArray)
	for card in cardsArray:
		move_child(card, cardsArray.find(card))

# Overridable function to allow the container to specify different
# effects to happen when a card is attempted to be added
# It should always return a valid node to put the card in
#
# For example, this can be used by a [Hand] to discard excess cards
# warning-ignore:unused_argument
func get_final_placement_node(card: Card) -> Node:
	return(self)

# Translates requested card index to true node index.
# By that, we mean the index the Card object it would have among all its
# siblings, inlcuding non-Card nodes
func translate_card_index_to_node_index(index: int) -> int:
	var node_index := 0
	# To figure out the index, we use the existing cards
	var all_cards := get_all_cards()
	# First we check if the requested index is higher than the amount of cards
	# If so, we give back the next available index
	if index > len(all_cards):
		node_index = len(all_cards)
		print_debug("WARNING: Higher card index than hosted cards requested on "
				+ name + ". Returning max position:" + str(node_index))
	else:
		# If the requester index is not higher than the number of cards
		# We figure out which card has the index at the moment, and return
		# its node index
		var card_at_index = all_cards[index]
		node_index = card_at_index.get_index()
	return node_index


# Adjusts the placement of the node, according to the placement var
# So that it always stays in the same approximate location
func re_place():
		var place := Vector2(0,0)
		# Here we match the adjust the default position based on the anchor
		# First we adjust the x position
		match placement:
			# Left position always start from x == 0,
			# which means left side of the viewport
			Anchors.TOP_LEFT, Anchors.LEFT_MIDDLE, Anchors.BOTTOM_LEFT:
				place.x = 0
				add_to_group("left")
			# Right position always start from the right-side of the viewport
			# minus the width of the container
			Anchors.TOP_RIGHT, Anchors.RIGHT_MIDDLE, Anchors.BOTTOM_RIGHT:
				place.x = get_viewport().size.x - (card_size.x * scale.x)
				add_to_group("right")
			# Middle placement is the middle of the viewport width,
			# minues half the height of the container
			Anchors.TOP_MIDDLE, Anchors.BOTTOM_MIDDLE:
				place.x = get_viewport().size.x / 2 - (card_size.x / 2 * scale.x)
		# Now we adjust the y position. Same logic for
		match placement:
			# Top position always start from y == 0,
			# which means top of the viewport
			Anchors.TOP_LEFT, Anchors.TOP_MIDDLE, Anchors.TOP_RIGHT:
				place.y = 0
				add_to_group("top")
			# Bottom position always start from the bottom of the viewport
			# minus the height of the container
			Anchors.BOTTOM_LEFT, Anchors.BOTTOM_MIDDLE, Anchors.BOTTOM_RIGHT:
				place.y = get_viewport().size.y - (card_size.y * scale.y)
				add_to_group("bottom")
			# Middle placement is the middle of the viewport height
			# minus half the height of the container
			Anchors.RIGHT_MIDDLE, Anchors.LEFT_MIDDLE:
				place.y = get_viewport().size.y / 2 - (card_size.y / 2 * scale.y)
		# Now we try to discover if more than one CardContainer share
		# the same anchor and the figure out which to displace.
		var duplicate_anchors := {}
		# All CardContainer belong to the "card_containers" group
		# So we gather them in a list
		for container in get_tree().get_nodes_in_group("card_containers"):
			# I could have made this code a bit more optimal
			# but Godot didn't like that sort of logic
			# So I just ensure each anchor is a key, and contains
			# an empty list
			if not duplicate_anchors.get(container.placement):
				duplicate_anchors[container.placement] = []
			# For each anchor, I add to the list all the CardContainers
			# which are placed in that anchor
			duplicate_anchors[container.placement].append(container)
		# Hook for the debugger
		if _debugger_hook:
			pass
		for anchor in duplicate_anchors:
			# I only iterate on the anchor that this CardContainer is set
			# And only if there's more than one CardContainer using it.
			if anchor == placement and duplicate_anchors[anchor].size() > 1:
				# This variable will hold all the CardContainers which share it
				var cc_array =  duplicate_anchors[anchor]
				# This function sorts the CardContainers sharing the same anchor
				# based on their preferred index to push.
				# If they're set to push the "lowest" index, then the
				# containers with thew lower index will be pushed to the
				# back of the array.
				# Otherwise the containers with the highest index will be at
				# The back of the array.
				# This allows us to control which node will be "pushed".
				cc_array.sort_custom(CFUtils,"sort_by_shift_priority")
				# We reset this variable every time
				accumulated_shift = Vector2(0,0)
				# Now we start going through the sorted array of CardContainers
				# Since the array is sorted from not-moved, to move-the-furthest
				# We will adjust the amount we move by the amount of others
				# Which we have passed through
				for cc in cc_array:
					# if we find self, then we stop. If self is the first
					# container in the array, this means it won't move at all
					if cc == self:
						place += accumulated_shift
						break
					# If we didn't find self, then we increase the amount
					# This container will move, by the combined size of
					# other containers in the array before it.
					match overlap_shift_direction:
						CFInt.OverlapShiftDirection.UP:
							accumulated_shift.y -= cc.control.rect_size.y
						CFInt.OverlapShiftDirection.DOWN:
							accumulated_shift.y += cc.control.rect_size.y
						CFInt.OverlapShiftDirection.LEFT:
							accumulated_shift.x -= cc.control.rect_size.x
						CFInt.OverlapShiftDirection.RIGHT:
							accumulated_shift.x += cc.control.rect_size.x
		# Finally, we move to the right location.
		position = place
		call_deferred("_init_control_size")
