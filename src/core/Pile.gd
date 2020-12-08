# A type of [CardContainer] that stores its [Card] objects optional visibility
# to the player and provides methods for retrieving and viewing them
class_name Pile
extends  CardContainer

# If this is set to true, cards on this stack will be placed face-up.
# Otherwise they will be placed face-down.
export var faceup_cards := false

# Popup View button for Piles
onready var view_button := $Control/ManipulationButtons/View
var init_position
# Position of the container when shuffling
var shuffle_position
# Angle of the container when shuffling
var shuffle_rotation
# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	view_button.connect("pressed",self,'_on_View_Button_pressed')
	# warning-ignore:return_value_discarded
	$ViewPopup.connect("popup_hide",self,'_on_ViewPopup_popup_hide')
	# warning-ignore:return_value_discarded
	$ViewPopup.connect("about_to_show",self,'_on_ViewPopup_about_to_show')


func _process(_delta) -> void:
	# This performs a bit of garbage collection to make sure no Control temp objects
	# are leftover empty in the popup
	for obj in $ViewPopup/CardView.get_children():
		if not obj.get_child_count():
			obj.queue_free()
	# We make sure to adjust our popup if cards were removed from it while it's open
	$ViewPopup.set_as_minsize()


# Populates the popup view window with all the cards in the deck
# then displays it
func _on_View_Button_pressed() -> void:
	# We prevent the button from being pressed twice while the popup is open
	# as it will bug-out
	$Control/ManipulationButtons.visible = false
	# We set the size of the grid to hold slightly scaled-down cards
	for card in get_all_cards(false):
		# We remove the card to rehost it in the popup grid container
		remove_child(card)
		_slot_card_into_popup(card)
	# Finally we Pop the Up :)
	$ViewPopup.popup_centered()


# Ensures the popup window interpolates to visibility when opened
func _on_ViewPopup_about_to_show() -> void:
	if not $ViewPopup/Tween.is_active():
		$ViewPopup/Tween.interpolate_property($ViewPopup,'modulate',
				Color(1,1,1,0), Color(1,1,1,1), 0.5,
				Tween.TRANS_EXPO, Tween.EASE_IN)
		$ViewPopup/Tween.start()


# Puts all [Card] objects to the root node once the popup view window closes
func _on_ViewPopup_popup_hide() -> void:
	$ViewPopup/Tween.remove_all()
	$ViewPopup/Tween.interpolate_property($ViewPopup,'modulate',
			Color(1,1,1,1), Color(1,1,1,0), 0.5,
			Tween.TRANS_EXPO, Tween.EASE_OUT)
	$ViewPopup/Tween.start()
	yield($ViewPopup/Tween, "tween_all_completed")
	for card in get_all_cards():
		# For each card we have hosted, we check if it's hosted in the popup.
		# If it is, we move it to the root.
		if "CardPopUpSlot" in card.get_parent().name:
			card.get_parent().remove_child(card)
			add_child(card)
			# We need to remember that cards in piles should be left invisible
			# and at default scale
			card.scale = Vector2(1,1)
			# We ensure that that closing popups reset card faceup to
			# whatever is the default for the pile
			if card.is_faceup != faceup_cards:
				card.set_is_faceup(faceup_cards,true)
			card.state = card.IN_PILE
	reorganize_stack()
	# We prevent the button from being pressed twice while the popup is open
	# as it will bug-out
	$Control/ManipulationButtons.visible = true

# Overrides the built-in add_child() method,
# To make sure the control node is set to be the last one among siblings.
# This way the control node intercepts any inputs.
#
# Also checks if the popup window is currently open, and puts the card
# directly there in that case.
func add_child(node, _legible_unique_name=false) -> void:
	if not $ViewPopup.visible:
		.add_child(node)
		if node as Card:
			# By raising the $Control every time a card is added
			# we ensure it's always drawn on top of the card objects
			$Control.raise()
	elif node as Card: # This triggers if the ViewPopup node is active
		# When the player adds card while the viewpopup is active
		# we move them automatically to the viewpopup grid.
		_slot_card_into_popup(node)


# Rearranges the position of the contained cards slightly
# so that they appear to be stacked on top of each other
func reorganize_stack() -> void:
	for c in get_all_cards():
		if c.position != Vector2(0.5 * get_card_index(c),
				-get_card_index(c)):
			c.position = Vector2(0.5 * get_card_index(c),
					-get_card_index(c))
	#The size of the panel has to be modified to be as large as the size of the cardd
	# TODO: This logic has to be adapted depending on where on the viewport
	# This pile is anchored. The below calculations assume bottom-left.
	$Control.rect_size = Vector2(156 + 0.5 * get_card_count(), 246 + get_card_count())
	$Control/Highlight.rect_size = $Control.rect_size
	# The highlight has to also be shifted higher or else it will just extend
	# below the viewport
	$Control/Highlight.rect_position.y = -get_card_count()


# Override the godot builtin move_child() method,
# to make sure the $Control node is always drawn on top of Card nodes
func move_child(child_node, to_position) -> void:
	.move_child(child_node, to_position)
	$Control.raise()


# Overrides [CardContainer] function to include cards in the popup window
# Returns an array with all children nodes which are of Card class
func get_all_cards(scanViewPopup := true) -> Array:
	var cardsArray := .get_all_cards()
	# For piles, we need to check if the card objects are inside the ViewPopup.
	if not len(cardsArray) and scanViewPopup:
		if $ViewPopup/CardView.get_child_count():
			# We know it's not possible to have a temp control container
			# (due to the garbage collection)
			# So we know if we find one, it will have 1 child,
			# which is a Card object.
			for obj in $ViewPopup/CardView.get_children():
				cardsArray.append(obj.get_child(0))
	return cardsArray


# Return the top a [Card] object from the pile.
func get_top_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "top" card in the pile
		# is the last node in the node hierarchy, so
		# to retrieve the last card placed, we choose the last index
		card = get_all_cards().back()
	return card # Returning the card object for unit testing


# Teturn the bottom [Card] object from the pile.
func get_bottom_card() -> Card:
	var card: Card = null
	# prevents from trying to retrieve more cards
	# than are in our deck and crashing godot.
	if get_card_count():
		# Counter intuitively, the "bottom" card in the pile
		# as it appears on screen, is the first node in the node hierarchy, so
		# to retrieve the last c
		card = get_card(0)
	return card # Returning the card object for unit testing


func get_stack_position(card: Card) -> Vector2:
	return Vector2(0.5 * get_card_index(card), -1 * get_card_index(card))

# Prepares a [Card] object to be added to the popup grid
func _slot_card_into_popup(card: Card) -> void:
	# We need to make the cards visible as they're by default invisible in piles
	#card.modulate[3] = 1
	# We also scale-down the cards to be able to see more at the same time.
	# We need to do it before we add the card object to the control temp,
	# otherwise it will default to the pre-scaled size
	card.scale = Vector2(0.75,0.75)
	# The grid container will only grid control objects
	# and the card nodes have an Area2D as a root
	# Therefore we instantatiate a new Control container
	# in which to put the card objects.
	var card_slot := Control.new()
	card_slot.set_name("CardPopUpSlot")
	# We set the control container size to be equal
	# to the card size to which the card will scale.
	card_slot.rect_min_size = card.get_node("Control").rect_min_size * card.scale
	$ViewPopup/CardView.add_child(card_slot)
	# Finally, the card is added to the temporary control node parent.
	card_slot.add_child(card)
	# warning-ignore:return_value_discarded
	card.set_is_faceup(true,true)
	card.position = Vector2(0,0)
	card.state = card.IN_POPUP

# Randomly rearranges the order of the [Card] nodes.
# Pile shuffling includes a fancy animation
func shuffle_cards(animate = true) -> void:
	if not $Tween.is_active() and animate:
		var last_card: Card
		# We move the pile to a more central location to see the anim
		_add_tween_position(position,shuffle_position,0.2)
		_add_tween_rotation(rotation_degrees,shuffle_rotation,0.2)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		if get_card_count() > 1:
			var random_cards = get_all_cards().duplicate()
			CardFrameworkUtils.shuffle_array(random_cards)
			last_card = random_cards.back()
			for card in random_cards:
				card.animate_shuffle()
				yield(get_tree().create_timer(0.05), "timeout")
		# This is where the shuffle actually happens
		# The effect looks like the cards shuffle in the middle of their
		# animations
		.shuffle_cards()
		yield(last_card._tween, "tween_all_completed")
		_add_tween_position(position,init_position,0.2)
		_add_tween_rotation(rotation_degrees,0,0.2)
		$Tween.start()
		yield($Tween, "tween_all_completed")
	else:
		# if we're already running another animation, just shuffle
		.shuffle_cards()
	reorganize_stack()


# Card rotation animation
func _add_tween_rotation(
		expected_rotation: float,
		target_rotation: float,
		runtime := 0.3,
		trans_type = Tween.TRANS_BACK,
		ease_type = Tween.EASE_IN_OUT):
	$Tween.remove(self,'rotation_degrees')
	$Tween.interpolate_property(self,'rotation_degrees',
			expected_rotation, target_rotation, runtime,
			trans_type, ease_type)


# Card position animation
func _add_tween_position(
		expected_position: Vector2,
		target_position: Vector2,
		runtime := 0.3,
		trans_type = Tween.TRANS_CUBIC,
		ease_type = Tween.EASE_OUT):
	$Tween.remove(self,'position')
	$Tween.interpolate_property(self,'position',
			expected_position, target_position, runtime,
			trans_type, ease_type)
