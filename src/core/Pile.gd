# A type of [CardContainer] that stores its [Card] objects optional visibility
# to the player and provides methods for retrieving and viewing them
class_name Pile
extends CardContainer

signal popup_closed


var is_popup_open := false
# Used to avoid performance-heavy checks in process
var _has_cards := false

# The pile's name. If this value is changed, it will change the
# `pile_name_label` text.
@export var pile_name: String: set = set_pile_name
# The shuffle style chosen for this pile. See CFConst.ShuffleStyle documentation.
@export var shuffle_style = CFConst.ShuffleStyle.AUTO # (CFConst.ShuffleStyle)
# If this is set to true, cards on this stack will be placed face-up.
# Otherwise they will be placed face-down.
@export var faceup_cards := false
# When true, when the cards are displayed in a popup, they will be sorted by name
# and not in their actual order
@export var sorted_popup := false


# The popup node
@onready var pile_popup := $ViewPopup
@onready var _popup_grid := $ViewPopup/CardView
# Popup View button for Piles
@onready var view_button := $Control/ManipulationButtons/View
@onready var view_sorted_button := $Control/ManipulationButtons/ViewSorted
# The label node where the pile_name is written.
@onready var pile_name_label := $Control/CenterContainer/VBoxContainer/Label
# The label node which shows the amount of cards in the pile.
@onready var card_count_label := $Control/CenterContainer/VBoxContainer\
		/PanelContainer/CenterContainer/CardCount

# The popup node
@onready var _opacity_tween: Tween
#@onready var _tween: Tween

var pre_sorted_order: Array

func _ready():
	super._ready()
	add_to_group("piles")
	# warning-ignore:return_value_discarded
	view_button.connect("pressed", Callable(self, '_on_View_Button_pressed'))
	# warning-ignore:return_value_discarded
	view_sorted_button.connect("pressed", Callable(self, '_on_ViewSorted_Button_pressed'))
	# warning-ignore:return_value_discarded
	$ViewPopup.connect("popup_hide", Callable(self, '_on_ViewPopup_popup_hide'))
	# warning-ignore:return_value_discarded
	$ViewPopup.connect("about_to_popup", Callable(self, '_on_ViewPopup_about_to_show'))
	set_pile_name(pile_name)
	# warning-ignore:return_value_discarded
	#connect("shuffle_completed", Callable(self, cfc.signal_propagator))
	connect("shuffle_completed", 
		Callable(cfc.signal_propagator, 
			"_on_signal_received")\
			.bind(["shuffle_completed",{"source": name}])
			)

func _process(_delta) -> void:
	pass
	# This performs a bit of garbage collection to make sure no Control temp objects
	# are leftover empty in the popup
	for obj in $ViewPopup/CardView.get_children():
		if not obj.get_child_count():
			obj.queue_free()
	# We make sure to adjust our popup if cards were removed from it while it's open
	$ViewPopup.reset_size()
	if _has_cards and cfc.game_settings.focus_style:
		var top_card = get_top_card()
		if cfc.NMAP.board.mouse_pointer in get_overlapping_areas()\
				and not cfc.card_drag_ongoing:
			if top_card and top_card.state == Card.CardState.IN_PILE:
				top_card.state = Card.CardState.VIEWED_IN_PILE
		elif top_card and top_card.state == Card.CardState.VIEWED_IN_PILE:
			top_card.state = Card.CardState.IN_PILE


# Populates the popup view window with all the cards in the deck
# then displays it
func _on_View_Button_pressed() -> void:
	populate_popup()


# Populates the popup view window with all the cards in the deck sorted by name
# then displays it
func _on_ViewSorted_Button_pressed() -> void:
	populate_popup(true)


# Ensures the popup window interpolates to visibility when opened
func _on_ViewPopup_about_to_show() -> void:
	if _tween:
		await _tween.finished
	_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	#it refuses to let me set a from .from(Color(1,1,1,0))\
	_tween.tween_property($ViewPopup,'modulate:a', Color(1,1,1,1), 0.5)
	_tween.play()

# Puts all [Card] objects to the root node once the popup view window closes
func _on_ViewPopup_popup_hide() -> void:
	if _tween:
		await _tween.finished
	_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	#.from(Color(1,1,1,1))
	_tween.tween_property($ViewPopup,'modulate:a', Color(1,1,1,0), 0.5)
	_tween.play()
	await _tween.finished
	for card in pre_sorted_order:
		# For each card we have hosted, we check if it's hosted in the popup.
		# If it is, we move it to the root.
#		print_debug(card.canonical_name, card.get_parent().name)
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
			else:
				card.ensure_proper()
			card.state = card.CardState.IN_PILE
	reorganize_stack()
	if show_manipulation_buttons:
		manipulation_buttons.visible = true
	emit_signal("popup_closed")
	is_popup_open = false


# Populated the popup card viewer with the cards and displays them
func populate_popup(sorted:= sorted_popup) -> void:
	# We prevent the button from being pressed twice while the popup is open
	# as it will bug-out
	manipulation_buttons.visible = false
	# We set the size of the grid to hold slightly scaled-down cards
	var card_array := get_all_cards(false)
	card_array.reverse()
	pre_sorted_order = get_all_cards()
	if sorted:
		card_array.sort_custom(Callable(CFUtils, "sort_scriptables_by_name"))
	for card in card_array:
		# We remove the card to rehost it in the popup grid container
		remove_child(card)
		_slot_card_into_popup(card)
	# Finally we Pop the Up :)
	$ViewPopup.popup_centered()
	is_popup_open = true
	card_count_label.text = str(get_card_count())


# Setter for pile_name.
# Also sets `pile_name_label` to the provided value.
func set_pile_name(value: String) -> void:
	# If the pile name has not been specified
	# we default to the node name instead
	if not pile_name:
		pile_name = name
	else:
		pile_name = value
	# if the pile name has been specified in the editor
	# this function will run before the onready calls
	# so the pile_name_will be empty
	if is_inside_tree():
		pile_name_label.text = value


# Overrides the built-in add_child() method,
# To make sure the control node is set to be the last one among siblings.
# This way the control node intercepts any inputs.
#
# Also checks if the popup window is currently open, and puts the card
# directly there in that case.
#TODO: I haven't touched this, because it's unclear exactly which calls to
# add_child are supposed to use this and which are supposed to use built-in
# Theoretically, GODOT should have never been calling this, but now it definitely won't
func add_child(node, _legible_unique_name=false, InternalMode=0) -> void:
	if not $ViewPopup.visible:
		super.add_child(node)
		if node as Card:
			_has_cards = true
			# By raising the $Control every time a card is added
			# we ensure it's always drawn on top of the card objects
			$Control.move_to_front()
			# If this was the first card which enterred this pile
			# We hide the pile "floor" by making it transparent
			if get_card_count() >= 1:
				#if _opacity_tween:
					#_opacity_tween.kill()
				#_opacity_tween = create_tween()
				#_opacity_tween.tween_property($Control, 'self_modulate:a', 0.4, 0.5)\
					#.from(Control.self_modulate.a).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				#_opacity_tween.play()
				card_count_label.text = str(get_card_count())
	elif node as Card: # This triggers if the ViewPopup node is active
		# When the player adds card while the viewpopup is active
		# we move them automatically to the viewpopup grid.
		_slot_card_into_popup(node)


# Overrides the function which removed chilren nodes so that it detects
# when a Card class is removed. In that case it also shows
# this container's "floor" if it was the last card in the pile.
func remove_child(node, _legible_unique_name=false) -> void:
	super.remove_child(node)
	card_count_label.text = str(get_card_count())
	# When we put the first card in the pile, we make sure the
	# Panel is made transparent so that the card backs are seen instead
	if get_card_count() == 0:
		_has_cards = false
		reorganize_stack()
		if _opacity_tween:
			await _opacity_tween.finished
		_opacity_tween = create_tween()
		_opacity_tween.tween_property($Control,'self_modulate:a',0.4, 0.5)\
			.from($Control.self_modulate.a).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_opacity_tween.play()
	else:
		$Control.self_modulate.a = 0.0


# Rearranges the position of the contained cards slightly
# so that they appear to be stacked on top of each other
func reorganize_stack() -> void:
	if are_cards_still_animating():
		return
#	while are_cards_still_animating():
#		yield(get_tree().create_timer(0.3), "timeout")
	for c in get_all_cards():
		if c.position != get_stack_position(c):
			c.position = get_stack_position(c)
	# The size of the panel has to be modified to be as large as the size
	# of the card stack
	# TODO: This logic has to be adapted depending on where on the viewport
	# This pile is anchored. The below calculations assume bottom-left.
	$Control.size = Vector2(card_size.x + 3 + _shift_x() * get_card_count(),
			card_size.y + 6 + _shift_y() * get_card_count())
	$Control/Highlight.size = $Control.size
	# The highlight has to also be shifted higher or else it will just extend
	# below the viewport
#	$Control/Highlight.rect_position.y = -get_card_count()
	super.re_place()
	# since we're adding cards towards the top, we do not want the re_place()
	# function to push the pile higher than the edge of the screen
	# it is supposed to be
	$Control.position = Vector2(0,0)
	$Control.position.y -= get_card_count()
	if "top" in get_groups():
		position.y += get_card_count() * _shift_y()
	if "right" in get_groups():
		position.x -= get_card_count() * _shift_x()
	$CollisionShape2D.shape.extents = $Control.size / 2
	$CollisionShape2D.position = $Control.position + $Control.size /2


# Override the godot builtin move_child() method,
# to make sure the $Control node is always drawn on top of Card nodes
func move_child(child_node, to_position) -> void:
	super.move_child(child_node, to_position)
	$Control.move_to_front()

# The top position of a pile, is always the lowest
func move_card_to_top(card: Card) -> void:
	var lowest_index = get_children().size() - 1
	move_child(card, lowest_index)
	reorganize_stack()

# Overrides [CardContainer] function to include cards in the popup window
# Returns an array with all children nodes which are of Card class
func get_all_cards(_scanViewPopup := true) -> Array:
	if is_popup_open:
		return(pre_sorted_order)
	else:
		return(super.get_all_cards())


# A wrapper for the CardContainer's get_last_card()
# which make sense for the cards' index in a pile
func get_top_card() -> Card:
	return(get_last_card())


# A wrapper for the CardContainer's get_first_card()
# which make sense for the cards' index in a pile
func get_bottom_card() -> Card:
	return(get_first_card())


# Returns the position among other cards the specified card should have.
func get_stack_position(card: Card) -> Vector2:
	@warning_ignore("unused_variable")
	var shift_x = 0.5 - 0.0014 * get_card_count()
	return Vector2(_shift_x() * get_card_index(card), -_shift_y() * get_card_index(card))

func _shift_x() -> float:
	return(0.5 - 0.0014 * get_card_count())

func _shift_y() -> float:
	return(1 - 0.0022 * get_card_count())

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
	card_slot.custom_minimum_size = card.get_node("Control").custom_minimum_size * card.scale
	$ViewPopup/CardView.add_child(card_slot)
	# Finally, the card is added to the temporary control node parent.
	card_slot.add_child(card)
	# warning-ignore:return_value_discarded
	card.set_is_faceup(true,true)
	card.position = Vector2(0,0)
	card.state = card.CardState.IN_POPUP


# Randomly rearranges the order of the [Card] nodes.
# Pile shuffling includes a fancy animation
func shuffle_cards(animate = true) -> void:
	# Optimally the CFConst.ShuffleStyle enum should be defined in this class
	# but if we did so, we would not be able to refer to it from the Card
	# class, as that would cause a cyclic dependency on the parser
	# So we've placed it in CFConst instead.
	#if not _tween.finished \
			#and animate \
			#and shuffle_style != CFConst.ShuffleStyle.NONE \
			#and get_card_count() > 1:
	if animate \
		and shuffle_style != CFConst.ShuffleStyle.NONE \
		and get_card_count() > 1:
		# The placement of this container in respect to the board.
		var init_position = position
		# The following calculation figures out the direction
		# towards the center of the viewport from the center of the card
		var shuffle_direction = (global_position + $Control.size/2)\
			.direction_to(get_viewport().size / 2)
		# We increase the intensity of the y direction, to make the shuffle
		# position move higher up or down respective to its position.
		shuffle_direction.y *= 2
		# Position of the container when shuffling. This is just the default
		# It can be overriden in each shuffle definition
		var shuffle_position = position + shuffle_direction * 300
		# Angle of the container when shuffling
		# The below calculation will be 10 if the card is on the left
		# or 10 if the card is on the right of the viewport center.
		var shuffle_rotation = (shuffle_position.x - position.x) \
				/ abs(shuffle_position.x - position.x) * 10
		# To make sure the shuffle draws above other objects
		z_index = 50
		# Handles how fast cards start animating after another.
		# If not used, all cards animate at the same time (e.g. see splash)
		var next_card_speed: float
		# How fast the tween animating the cards will go.
		var anim_speed: float
		var style: int
		var card_count = get_card_count()
		# If the style is auto, we've predefined some animations that fit
		# The amount of cards in the deck
		if shuffle_style == CFConst.ShuffleStyle.AUTO:
			if card_count <= 30:
				style = CFConst.ShuffleStyle.CORGI
			elif card_count <= 60:
				style = CFConst.ShuffleStyle.SPLASH
			else:
				style = CFConst.ShuffleStyle.OVERHAND
		# if the style is random, we select a random shuffle animation among
		# the predefined ones.
		elif shuffle_style == CFConst.ShuffleStyle.RANDOM:
			style = CFUtils.randi_range(3, len(CFConst.ShuffleStyle) - 1)
		else:
			style = shuffle_style
		if style == CFConst.ShuffleStyle.CORGI:
			if _tween:
				await _tween.finished
			_tween = create_tween()
			_tween.stop()
			_add_tween_position(position,shuffle_position,0.2)
			_add_tween_rotation(rotation_degrees,shuffle_rotation,0.2)
			_tween.play()
			# We move the pile to a more central location to see the anim
			await _tween.finished
			# The animation speeds have been empirically tested to look good
			next_card_speed = 0.05 - 0.002 * card_count
			if next_card_speed < 0.01:
				next_card_speed = 0.01
			anim_speed = 0.4 - 0.005 * card_count
			if anim_speed < 0.05:
				anim_speed = 0.05
			var random_cards = get_all_cards().duplicate()
			CFUtils.shuffle_array(random_cards)
			for card in random_cards:
				card.animate_shuffle(anim_speed,CFConst.ShuffleStyle.CORGI)
				await get_tree().create_timer(next_card_speed).timeout
			# This is where the shuffle actually happens
			# The effect looks like the cards shuffle in the middle of their
			# animations
			super.shuffle_cards()
			# This wait gives the carde enough time to return to
			# their original position.
			await get_tree().create_timer(anim_speed * 2.5).timeout
		elif style == CFConst.ShuffleStyle.SPLASH:
			if _tween:
				await _tween.finished
			_tween = create_tween()
			_tween.stop()
			_add_tween_position(position,shuffle_position,0.2)
			_add_tween_rotation(rotation_degrees,shuffle_rotation,0.2)
			_tween.play()
			await _tween.finished
			# The animation speeds have been empirically tested to look good
			anim_speed = 0.6
			for card in get_all_cards():
				card.animate_shuffle(anim_speed, CFConst.ShuffleStyle.SPLASH)
			# This has been timed to "splash" the cards at the exact moment
			# The shuffle happens, which makes the z-index change
			# unnoticeable to the player
			await get_tree().create_timer(anim_speed - 0.5).timeout
			super.shuffle_cards()
			# The extra time is to give the cards enough time to return
			# To the starting location, and let reorganize_stack() do its magic
			await get_tree().create_timer(anim_speed + 0.6).timeout
		elif style == CFConst.ShuffleStyle.SNAP:
			if _tween:
				await _tween.finished
			_tween = create_tween()
			_tween.stop()
			_add_tween_position(position,shuffle_position,0.2)
			_add_tween_rotation(rotation_degrees,shuffle_rotation,0.2)
			_tween.play()
			await _tween.finished
			anim_speed = 0.2
			var card = get_random_card()
			card.animate_shuffle(anim_speed, CFConst.ShuffleStyle.SNAP)
			await get_tree().create_timer(anim_speed * 2.5).timeout
			super.shuffle_cards()
		elif style == CFConst.ShuffleStyle.OVERHAND:
			anim_speed = 0.15
			for _i in range(3):
				var random_cards = get_all_cards().duplicate()
				CFUtils.shuffle_array(random_cards)
				# This calulcation prevents us from trying to tween too many
				# cards at the same time,when the deck is too big
				# The bigger the deck, the smallest the percentage of cards
				# in it, that will bounce
				var resize_div: float = 2 + 0.1 * random_cards.size()
				random_cards.resize(random_cards.size() / resize_div)
				for card in random_cards:
					card.animate_shuffle(anim_speed, CFConst.ShuffleStyle.OVERHAND)
				await get_tree().create_timer(anim_speed * 2.3).timeout
				# The shuffle after every jump in a face-up pile
				# really sells it :)
				super.shuffle_cards()
				reorganize_stack()
		if position != init_position:
			if _tween:
				await _tween.finished
			_tween = create_tween()
			_tween.stop()
			_add_tween_position(position,init_position,0.2)
			_add_tween_rotation(rotation_degrees,0,0.2)
			_tween.play()
		z_index = 0
	else:
		# if we're already running another animation, just shuffle
		super.shuffle_cards()
	reorganize_stack()
	emit_signal("shuffle_completed", self)


# Overrides the re_place() function of [Pile] in order
# to also restack the cards
func re_place() -> void:
	# reorganize_stack() calls .re_place() at the end
	reorganize_stack()


# Card rotation animation
func _add_tween_rotation(
		expected_rotation: float,
		target_rotation: float,
		runtime := 0.3,
		trans_type = Tween.TRANS_BACK,
		ease_type = Tween.EASE_IN_OUT):
	_tween.tween_property(self,'rotation_degrees', target_rotation, runtime).from(expected_rotation)\
		.set_trans(trans_type).set_ease(ease_type)



# Card position animation
func _add_tween_position(
		expected_position: Vector2,
		target_position: Vector2,
		runtime := 0.3,
		trans_type = Tween.TRANS_CUBIC,
		ease_type = Tween.EASE_OUT):
	_tween.tween_property(self,'position',target_position, runtime).from(expected_position)\
		.set_trans(trans_type).set_ease(ease_type)
