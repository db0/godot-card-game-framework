# A basic card object which includes functionality for handling its own
# placement and focus.
#
# This class is meant to be used as the basis for your card scripting
# Simply make your card scripts extend this class and you'll have all the
# provided scripts available.
# If your card node type is not Area2D, make sure you change the extends type.
class_name Card
extends Area2D

# All the Card's Finite State Machine states
#
# This simply is a way to refer to the values with a human-readable name.
#
# See _process_card_state()
enum{
	IN_HAND					#0
	FOCUSED_IN_HAND			#1
	MOVING_TO_CONTAINER		#2
	REORGANIZING			#3
	PUSHED_ASIDE			#4
	DRAGGED					#5
	DROPPING_TO_BOARD		#6
	ON_PLAY_BOARD			#7
	FOCUSED_ON_BOARD		#8
	DROPPING_INTO_PILE 		#9
	IN_PILE					#10
	FOCUSED_IN_POPUP		#11
}

# The possible return codes a function can return
#
# OK is returned when the function did not end up doing any changes
#
# CHANGE is returned when the function modified the card properties in some way
#
# FAILED is returned when the function failed to modify the card for some reason
enum _ReturnCode {
	OK,
	CHANGED,
	FAILED,
}

const token_scene = preload("res://src/core/Token.tscn")
# We export this variable to the editor to allow us to add scripts to each card
# object directly instead of only via code.
# warning-ignore:unused_class_variable
export var scripts := [{'name':'','args':['',0]}]
# If true, the card can be attached to other cards and will follow
# their host around the table. The card will always return to its host
# when dragged away
export var is_attachment := false setget set_is_attachment, get_is_attachment
# If true, the card will be displayed faceup. If false, it will be facedown
export var is_faceup  := true setget set_is_faceup, get_is_faceup
# Specifies the card rotation in increments of 90 degrees
export var is_viewed  := false setget set_is_viewed, get_is_viewed
# Specifies the card rotation in increments of 90 degrees
export(int, 0, 270, 90) var card_rotation  := 0 setget set_card_rotation, get_card_rotation

# Used to store a card succesfully targeted.
# It should be cleared from whichever effect requires a target once it has finished
var target_card : Card = null setget set_targetcard, get_targetcard
# Starting state for each card
var state := IN_PILE
# If this card is hosting other card, this list retains links to their objects in order
var attachments := []
# If this card is set as an attachment to another card, this tracks who its host is
var current_host_card : Card = null
# A dictionary holding all the tokens placed on this card
var tokens := {} setget ,get_all_tokens

# To track that this card attempting to target another card
var _is_targetting := false
# Used for animating the card
var _target_position: Vector2
# Used to avoid the focus animation repeating once it's completed.
var _focus_completed: bool = false
# We use this to know at which stage of fancy movement this is.
var _fancy_move_second_part := false
# We use this to track multiple cards when our card is about to drop onto or target them
var _potential_cards := []
# Used for looping between brighness scales for the Cardback glow
# The multipliers have to be small, as even small changes increase
# brightness a lot
var _pulse_values := [Color(1.05,1.05,1.05),Color(0.9,0.9,0.9)]
# A flag on whether the token drawer is currently open
var _is_drawer_open := false

# Debug for stuck tweens
var _tween_stuck_time = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# First we set the card to always pivot from its center.
	# We only rotate the Control node however, so the collision shape is not rotated
	# Looking for a better solution, but this is the best I have until now.
	$Control.rect_pivot_offset = $Control.rect_size/2
	# We set the card's Highlight to always extend 3 pixels over
	# Either side of the card. This way its border will appear
	# correctly when hovering over the card.
	$Control/FocusHighlight.rect_size = $Control.rect_size + Vector2(6,6)
	$Control/FocusHighlight.rect_position = Vector2(-3,-3)
	# We set the targetting arrow modulation to match our config specification
	$TargetLine.default_color = cfc.TARGETTING_ARROW_COLOUR
	$TargetLine/ArrowHead.color = cfc.TARGETTING_ARROW_COLOUR
	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_Card_area_entered")
	# warning-ignore:return_value_discarded
	connect("area_exited", self, "_on_Card_area_exited")
	# warning-ignore:return_value_discarded
	$TargetLine/ArrowHead/Area2D.connect("area_entered", self, "_on_ArrowHead_area_entered")
	# warning-ignore:return_value_discarded
	$TargetLine/ArrowHead/Area2D.connect("area_exited", self, "_on_ArrowHead_area_exited")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_entered", self, "_on_Card_mouse_entered")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_exited", self, "_on_Card_mouse_exited")
	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", self, "_on_Card_gui_input")
	# warning-ignore:return_value_discarded
	$Control/Tokens/Drawer/VBoxContainer.connect("sort_children", self, "_on_VBoxContainer_sort_children")
	# warning-ignore:return_value_discarded
	for button in $Control/ManipulationButtons.get_children():
		if button.name != "Tween":
			button.connect("mouse_entered",self,"_on_button_mouse_entered")
			button.connect("mouse_exited",self,"_on_button_mouse_exited")
	$Control/ManipulationButtons/Rot90.connect("pressed",self,'_on_Rot90_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/Rot180.connect("pressed",self,'_on_Rot180_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/Flip.connect("pressed",self,'_on_Flip_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/AddToken.connect("pressed",self,'_on_AddToken_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/View.connect("pressed",self,'_on_View_pressed')
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists before we connect
	if $Control/Back.has_node('Pulse'):
		# warning-ignore:return_value_discarded
		$Control/Back/Pulse.connect("tween_all_completed", self, "_on_Pulse_completed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if $Tween.is_active() and not cfc.UT: # Debug code for catch potential Tween deadlocks
		_tween_stuck_time += delta
		if _tween_stuck_time > 2 and int(fmod(_tween_stuck_time,3)) == 2 :
			print("Tween Stuck for ",_tween_stuck_time,
					"seconds. Reports leftover runtime: ",$Tween.get_runtime ( ))
			$Tween.remove_all()
			_tween_stuck_time = 0
	else:
		_tween_stuck_time = 0
	if _is_targetting:
		_draw_targeting_arrow()
	_process_card_state()
	# Having to do all these checks due to godotengine/godot#16854
	if _is_drawer_open and not _is_drawer_hovered() and not _is_card_hovered():
		_on_Card_mouse_exited()


func _on_Card_mouse_entered() -> void:
	# This triggers the focus-in effect on the card
	#print(state,":enter:",get_index()) # Debug
	#print($Control/Tokens/Drawer/VBoxContainer.rect_size) # debug
	# We use this variable to check if mouse thinks it changed nodes because
	# it just entered a child node
	if not (_are_buttons_hovered() and not _is_drawer_hovered()) or \
			((_are_buttons_hovered() ) and not get_focus()):
		match state:
			IN_HAND, REORGANIZING, PUSHED_ASIDE:
				if not cfc.card_drag_ongoing:
					#print("focusing:",get_my_card_index()) # debug
					interruptTweening()
					state = FOCUSED_IN_HAND
			ON_PLAY_BOARD:
					state = FOCUSED_ON_BOARD
			# The only way to mouse over a card in a pile, is when
			# it's in a the grid popup
			IN_PILE:
					state = FOCUSED_IN_POPUP


# A signal for whenever the player clicks on a card
func _on_Card_gui_input(event) -> void:
	if event is InputEventMouseButton:
		# If the player presses the left click, it might be because
		# they want to drag the card
		if event.is_pressed() and event.get_button_index() == 1:
			if (cfc.focus_style != cfc.FocusStyle.VIEWPORT and
					(state == FOCUSED_IN_HAND
					or state == FOCUSED_ON_BOARD)) or cfc.focus_style:
				# But first we check if the player does a long-press.
				# We don't want to start dragging the card immediately.
				cfc.card_drag_ongoing = self
				# We need to wait a bit to make sure the other card has a chance
				# to go through their scripts
				yield(get_tree().create_timer(0.1), "timeout")
				# If this variable is still set to true,
				# it means the mouse-button is still pressed
				# We also check if another card is already selected for dragging,
				# to prevent from picking 2 cards at the same time.
				if cfc.card_drag_ongoing == self:
					# While the mouse is kept pressed, we tell the engine
					# that a card is being dragged
					_start_dragging()
		# If the mouse button was released we drop the dragged card
		# This also means a card clicked once won't try to immediately drag
		if not event.is_pressed() and event.get_button_index() == 1:
			# Always reveal the mouseon unclick
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Control.set_default_cursor_shape(Input.CURSOR_ARROW)
			cfc.card_drag_ongoing = null
			match state:
				DRAGGED:
					# if the card was being dragged, it's index is very high
					# to always draw above other objects
					# We need to reset it either to the default of 0
					# Or if the card was left overlapping with other cards,
					# the higher index among them
					z_index = 0
					var destination = cfc.NMAP.board
					for obj in get_overlapping_areas():
						if obj.get_class() == 'CardContainer':
							#TODO: Need some more player-obvious logic on
							# what to do if card area overlaps two CardContainers
							destination = obj
					move_to(destination)
					_focus_completed = false
					#emit_signal("card_dropped",self)
		if event.is_pressed() and event.get_button_index() == 2:
			initiate_targeting()
		if not event.is_pressed() and event.get_button_index() == 2:
			complete_targeting()


# Triggers the focus-out effect on the card
func _on_Card_mouse_exited() -> void:
	# On exiting this node, we wait a tiny bit to make sure the mouse didn't
	# just enter a child button
	# If it did, then that button will immediately set a variable to let us know
	# not to restart the focus
	#print(state,":exit:",get_index()) # debug
	#print(_are_buttons_hovered()) # debug
	# We use this variable to check if mouse thinks it changed nodes
	# because it just entered a child node
	if not _are_buttons_hovered() and not _is_drawer_hovered():
		match state:
			FOCUSED_IN_HAND:
				#_focus_completed = false
				# To avoid errors during fast player actions
				if get_parent() in cfc.hands:
					for c in get_parent().get_all_cards():
						# We need to make sure afterwards all card will return
						# to their expected positions
						# Therefore we simply stop all tweens and reorganize the whole hand
						c.interruptTweening()
						# This will also set the state to IN_HAND afterwards
						c.reorganizeSelf()
			FOCUSED_ON_BOARD:
				state = ON_PLAY_BOARD
			FOCUSED_IN_POPUP:
				state = IN_PILE


# Resizes Token Drawer to min size whenever a token is removed completely.
#
# Without this, the token drawer would stay at the highest size it reached.
func _on_VBoxContainer_sort_children() -> void:
	$Control/Tokens/Drawer/VBoxContainer.rect_size = \
			$Control/Tokens/Drawer/VBoxContainer.rect_min_size
	# We need to resize it's parent too
	$Control/Tokens/Drawer.rect_size = \
			$Control/Tokens/Drawer.rect_min_size


func _on_button_mouse_entered() -> void:
	match state:
		ON_PLAY_BOARD:
			$Control/ManipulationButtons/Tween.remove_all()
			$Control/ManipulationButtons.modulate[3] = 1


# Makes the hoverable buttons invisible when mouse is not hovering over the card
func _on_button_mouse_exited() -> void:
	if not get_focus():
		$Control/ManipulationButtons/Tween.remove_all()
		$Control/ManipulationButtons.modulate[3] = 0


# Hover button which rotates the card 90 degrees
func _on_Rot90_pressed() -> void:
# warning-ignore:return_value_discarded
	set_card_rotation(90, true)


# Hover button which rotates the card 180 degrees
func _on_Rot180_pressed() -> void:
# warning-ignore:return_value_discarded
	set_card_rotation(180, true)


# Hover button which flips the card facedown/faceup
func _on_Flip_pressed() -> void:
	# warning-ignore:return_value_discarded
	set_is_faceup(not is_faceup)


# Demo hover button which adds a selection of random tokens
func _on_AddToken_pressed() -> void:
	var valid_tokens := ['tech','gold coin','blood','plasma']
	randomize()
	# warning-ignore:return_value_discarded
	add_token(valid_tokens[randi()%len(valid_tokens)])


# Hover button which allows the player to view a facedown card
func _on_View_pressed() -> void:
	# warning-ignore:return_value_discarded
	set_is_viewed(true)


# Triggers when a card hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as hosts
func _on_Card_area_entered(card: Card) -> void:
	if (card and is_attachment and not card in attachments):
		# The below 'if', checks if the card we're hovering has already been considered
		# If it hasn't we add it to an array of all the cards we're hovering
		# onto at the moment, at the same time
		# But we only care for cards on the table, and only while this card is
		# the one being dragged
		if (not card in _potential_cards and
				card.get_parent() == cfc.NMAP.board and
				cfc.card_drag_ongoing == self):
			# We add the card to the list which tracks out simultaneous hovers
			_potential_cards.append(card)
			# We sort all potential cards by their index
			_potential_cards.sort_custom(CardIndexSorter,"sort_index_ascending")
			# Finally we use a method which  handles changing highlights on the
			# top index card
			highlight_potential_card(cfc.HOST_HOVER_COLOUR)


# Triggers when a card stops hovering over another
#
# It clears potential highlights and adjusts potential cards as hosts
func _on_Card_area_exited(card: Card) -> void:
	if card:
		# We only do any step if the card we exited was already considered and
		# was on the board
		# And only while this is the card being dragged
		if (card in _potential_cards and
				card.get_parent() == cfc.NMAP.board
				and cfc.card_drag_ongoing == self):
			# We remove the card we stopped hovering from the _potential_cards
			_potential_cards.erase(card)
			# And we explicitly hide its cards focus since we don't care about
			# it anymore
			card.set_highlight(false)
			# Finally, we make sure we highlight any other cards we're still hovering
			highlight_potential_card(cfc.HOST_HOVER_COLOUR)


# Triggers when a targetting arrow hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as targets.
func _on_ArrowHead_area_entered(card: Card) -> void:
	if card and not card in _potential_cards:
		_potential_cards.append(card)
		_potential_cards.sort_custom(CardIndexSorter,"sort_index_ascending")
		highlight_potential_card(cfc.TARGET_HOVER_COLOUR)


# Triggers when a targetting arrow stops hovering over a card
#
# It clears potential highlights and adjusts potential cards as targets
func _on_ArrowHead_area_exited(card: Card) -> void:
	if card and card in _potential_cards:
		# We remove the card we stopped hovering from the _potential_cards
		_potential_cards.erase(card)
		# And we explicitly hide its cards focus since we don't care about it anymore
		card.set_highlight(false)
		# Finally, we make sure we highlight any other cards we're still hovering
		highlight_potential_card(cfc.TARGET_HOVER_COLOUR)


# Reverses the card back pulse and starts it again
func _on_Pulse_completed() -> void:
	# We only pulse the card if it's face-down and on the board
	if not is_faceup and get_parent() == cfc.NMAP.board:
		_pulse_values.invert()
		_start_pulse()
	else:
		_stop_pulse()


# Setter for _is_attachment
func set_is_attachment(value: bool) -> void:
	is_attachment = value


# Getter for _is_attachment
func get_is_attachment() -> bool:
	return is_attachment


# Setter for target_card
func set_targetcard(card: Card) -> void:
	target_card = card


# Getter for target_card
func get_targetcard() -> Card:
	return target_card


# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# Returns _ReturnCode.CHANGED if the card actually changed rotation
#
# Returns _ReturnCode.OK if the card was already in the correct rotation
func set_is_faceup(value: bool) -> int:
	var retcode: int
	if value == is_faceup:
		retcode = _ReturnCode.OK
	else:
		if _is_drawer_open:
			_token_drawer(false)
		# We make sure to remove other tweens of the same type to avoid a deadlock
		is_faceup = value
		# When we change faceup state, we reset the is_viewed to false
		if set_is_viewed(false) == _ReturnCode.FAILED:
			print("ERROR: Something went unexpectedly in set_is_faceup")
		if value:
			_flip_card($Control/Back, $Control/Front)
			$Control/ManipulationButtons/View.visible = false
			_stop_pulse()
			# When we flip face up, we also want to show the dupe card
			# in the focus viewport
			# However we also need to protect this call from the dupe itself
			# calling it when it hasn't yet been added to its parent
			if cfc.NMAP.get("main", null) and get_parent():
				# we need to check if there's actually a viewport focus
				# card, as we may be flipping the card via code
				if len(cfc.NMAP.main._previously_focused_cards):
					# The currently active viewport focus is always in the
					# _previously_focused_cards list, as the last card
					var dupe_card = cfc.NMAP.main._previously_focused_cards.back()
					var dupe_front = dupe_card.get_node("Control/Front")
					var dupe_back = dupe_card.get_node("Control/Back")
					_flip_card(dupe_back, dupe_front, true)
		else:
			_flip_card($Control/Front, $Control/Back)
			$Control/ManipulationButtons/View.visible = true
			if get_parent() == cfc.NMAP.board:
				_start_pulse()
			# When we flip face down, we also want to hide the dupe card
			# in the focus viewport
			# However we also need to protect this call from the dupe itself
			# calling it when it hasn't yet been added to its parent
			if cfc.NMAP.get("main", null):
				# we need to check if there's actually a viewport focus
				# card, as we may be flipping the card via code
				if len(cfc.NMAP.main._previously_focused_cards):
					var dupe_card = cfc.NMAP.main._previously_focused_cards.back()
					var dupe_front = dupe_card.get_node("Control/Front")
					var dupe_back = dupe_card.get_node("Control/Back")
					_flip_card(dupe_front, dupe_back, true)
		retcode = _ReturnCode.CHANGED
	return retcode


# Getter for is_faceup
func get_is_faceup() -> bool:
	return is_faceup


# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# Returns _ReturnCode.CHANGED if the card actually changed view status
#
# Returns _ReturnCode.OK if the card was already in the correct view status
#
# Returns _ReturnCode.FAILED if changing the status is now allowed
func set_is_viewed(value: bool) -> int:
	var retcode: int
	if value == true:
		if is_faceup == true:
			# Players can already see faceup cards
			retcode = _ReturnCode.FAILED
		elif value == is_viewed:
			retcode = _ReturnCode.OK
		else:
			is_viewed = true
			if get_parent() != null:
				var dupe_front = cfc.NMAP.main._previously_focused_cards.back().get_node("Control/Front")
				var dupe_back = cfc.NMAP.main._previously_focused_cards.back().get_node("Control/Back")
				_flip_card(dupe_back, dupe_front, true)
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = true
			retcode = _ReturnCode.CHANGED
	else:
		if value == is_viewed:
			retcode = _ReturnCode.OK
		elif is_faceup == true:
			retcode = _ReturnCode.CHANGED
			is_viewed = false
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = false
		else:
			# We don't allow players to unview cards
			retcode = _ReturnCode.FAILED
	return retcode


# Getter for is_faceup
func get_is_viewed() -> bool:
	return is_viewed


# Setter for card_rotation.
#
# Rotates the card the specified number of degrees.
#
# If the caller specifies the degree the card already has,
# and they have enabled the toggle flag,
# then we just reset the card to 0 degrees.
#
# Returns _ReturnCode.CHANGED if the card actually changed rotation.
#
# Returns _ReturnCode.OK if the card was already in the correct rotation.
#
# Returns _ReturnCode.FAILED if an invalid rotation was specified.
func set_card_rotation(value: int, toggle := false) -> int:
	var retcode
	# For cards we only allow orthogonal degrees of rotation
	# If it's not, we consider the request failed
	if not value in [0,90,180,270] or \
		not (state == ON_PLAY_BOARD or state == FOCUSED_ON_BOARD):
		retcode = _ReturnCode.FAILED
	# If the card is already in the specified rotation
	# and a toggle was not requested, we consider we did nothing
	elif value == $Control.rect_rotation and not toggle:
		retcode = _ReturnCode.OK
	else:
		# If the toggle was specified then if the card matches the requested
		# rotation, we reset it to 0 degrees
		if $Control.rect_rotation == value and toggle:
			value = 0
		# We make sure to remove other tweens of the same type to avoid a deadlock
		$Tween.remove($Control,'rect_rotation')
		# There's no way to rotate the Area2D node,
		# so we just rotate the internal $Control. The results are the same.
		$Tween.interpolate_property($Control,'rect_rotation',
				$Control.rect_rotation, value, 0.3,
				Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		$Tween.start()
		#$Control/Tokens.rotation_degrees = -value # need to figure this out
		# When the card actually changes orientation
		# We report that it changed.
		retcode = _ReturnCode.CHANGED
	return retcode

# Getter for card_rotation
func get_card_rotation() -> int:
	return card_rotation

# Arranges so that the card enters the chosen container.
#
# Will take care of interpolation.
#
# If the target container is the board, the card will either be placed at the
# mouse position, or at the 'boardPosition' variable if it's provided
# index determines the card's position among other cards.
func move_to(targetHost: Node2D, index := -1, boardPosition := Vector2(-1,-1)) -> void:
#	if cfc.focus_style:
#		# We make to sure to clear the viewport focus because
#		# the mouse exited signal will not fire after drag&drop in a container
#		cfc.NMAP.main.unfocus()
	# We need to store the parent, because we won't be able to know it later
	var parentHost = get_parent()
	# We want to keep the token drawer closed during movement
	if _is_drawer_open:
		_token_drawer(false)
	if targetHost != parentHost:
		# When changing parent, it resets the position of the child it seems
		# So we store it to know where the card used to be, before moving it
		var previous_pos = global_position
		var global_pos = global_position
		# We need to remove the current parent node before adding a different one
		parentHost.remove_child(self)
		targetHost.add_child(self)
		# The below is used when a specific card position is requested
		# It converts the requested card position, to absolute node position
		# between all nodes
		if index >= 0:
			targetHost.move_child(self,
					targetHost.translate_card_index_to_node_index(index))
		# Ensure card stays where it was before it changed parents
		global_position = previous_pos
		if targetHost in cfc.hands:
			_tween_interpolate_visibility(1,0.3)
			# We need to adjust the start position based on the global position
			# coordinates as they would be inside the hand control node
			# So we transform global coordinates to hand rect coordinates.
			previous_pos = targetHost.to_local(global_pos)
			# The end position is always the final position the card would be
			# inside the hand
			_target_position = _recalculatePosition()
			state = MOVING_TO_CONTAINER
			# We reorganize the left over cards in hand.
			for c in targetHost.get_all_cards():
				if c != self:
					c.interruptTweening()
					c.reorganizeSelf()
			if set_is_faceup(true) == _ReturnCode.FAILED:
				print("ERROR: Something went unexpectedly in set_is_faceup")
		elif targetHost in cfc.piles:
			# Added because sometimes it ended up stuck and a card remained
			# visible on top of deck
			$Tween.remove_all()
			# We need to adjust the end position based on the local rect inside
			# the container control node
			# So we transform global coordinates to container rect coordinates.
			previous_pos = targetHost.to_local(global_pos)
			# The target position is always local coordinates 0,0 of the final container
			_target_position = Vector2(0,0)
			state = MOVING_TO_CONTAINER
			# If we have fancy movement, we need to wait for 2 tweens to finish
			# before we vanish the card.
			# One for the fancy move, and then the move to the final position
			if set_is_faceup(false) == _ReturnCode.FAILED:
				print("ERROR: Something went unexpectedly in set_is_faceup")
			if cfc.fancy_movement:
				print("tween_all_completed")
				yield($Tween, "tween_all_completed")
			_tween_interpolate_visibility(0,0.3)
		else:
			interruptTweening()
			if len(_potential_cards):
				# The _potential_cards are always organized so that the card higher
				# in index that we were hovering over, is the last in the array.
				attach_to_host(_potential_cards.back())
			else:
				# The developer is allowed to pass a position override to the
				# card placement
				if boardPosition == Vector2(-1,-1):
					_determine_target_position_from_mouse()
				else:
					_target_position = boardPosition
				raise()
			state = DROPPING_TO_BOARD
		if parentHost in cfc.hands:
			# We also want to rearrange the hand when we take cards out of it
			for c in parentHost.get_all_cards():
				# But this time we don't want to rearrange ourselves, as we're
				# in a different container by now
				if c != self and c.state != DRAGGED:
					c.interruptTweening()
					c.reorganizeSelf()
		elif parentHost == cfc.NMAP.board:
			# If the card was or had attachments and it is removed from the table,
			# all attachments status is cleared
			_clear_attachment_status()
			# If the card has tokens, and TOKENS_ONLY_ON_BOARD is true
			# we remove all tokens
			if cfc.TOKENS_ONLY_ON_BOARD:
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.queue_free()
			# When the card was removed from the board, we need to make sure it
			# recovers to 0 degress rotation
			# We make sure to remove other tweens of the same type to avoid a deadlock
			$Tween.remove($Control,'rect_rotation')
			$Tween.interpolate_property($Control,'rect_rotation',
					$Control.rect_rotation, 0, 0.2,
					Tween.TRANS_QUINT, Tween.EASE_OUT)
			# We also make sure the card buttons don't stay visible or enabled
			$Control/ManipulationButtons/Tween.remove_all()
			$Control/ManipulationButtons.modulate[3] = 0
	else:
		# Here we check what to do if the player just moved the card back
		# to the same container
		if parentHost == cfc.NMAP.hand:
			state = IN_HAND
			reorganizeSelf()
		if parentHost == cfc.NMAP.board:
			# Checking if this is an attachment and we're looking for a new host
			if len(_potential_cards):
				attach_to_host(_potential_cards.back())
			# If we are an attachment and were moved elsewhere
			# We reset the position.
			elif current_host_card:
				var attach_index = current_host_card.attachments.find(self)
				_target_position = (current_host_card.global_position
						 + Vector2(0,(attach_index + 1)
						* $Control.rect_size.y
						* cfc.ATTACHMENT_OFFSET))
			else:
				_determine_target_position_from_mouse()
				raise()
			state = DROPPING_TO_BOARD
	# Just in case there's any leftover potential host highlights
	if len(_potential_cards):
		for card in _potential_cards:
			card.set_highlight(false)
		_potential_cards.clear()


# Handles the card becoming an attachment for a specified host Card object
func attach_to_host(host: Card, follows_previous_host = false) -> void:
	# First we check if the selected host is not the current host anyway.
	# If it is, we do nothing else
	if host != current_host_card:
		# If we already had a host, we clear our state with it
		# I don't know why, but logic breaks if I don't use the follows_previous_host flag
		# It should work without it, but it doesn't
		if current_host_card and not follows_previous_host:
			current_host_card.attachments.erase(self)
		current_host_card = host
		# Once we selected the host, we don't need anything in the array anymore
		_potential_cards.clear()
		# We also clear the highlights on our new host
		current_host_card.set_highlight(false)
		# We set outselves as an attachment on the target host for easy iteration
		current_host_card.attachments.append(self)
		#print(current_host_card.attachments)
		# We make existing attachments reattach to the new host directly
		# Otherwise it becomes too complex to handle attachment indexes
		for card in attachments:
			card.attach_to_host(host,true)
		attachments.clear()
		# The position below the host is based on how many other attachments it has
		# We offset our position below the host based on a percentage of
		# the card size, times the index among other attachments
		var attach_index = current_host_card.attachments.find(self)
		_target_position = (current_host_card.global_position
				+ Vector2(0,(attach_index + 1)
				* $Control.rect_size.y
				* cfc.ATTACHMENT_OFFSET))


# Executes card scripts
func card_action() -> void:
	pass


# Overrides the built-in get_class to
# Returns "Card" instead of "Area2D"
func get_class(): return "Card"


# Ensures the card is placed in the right position in the hand
# In relation to the other cards in the hand
#
# It will also adjust the separation between cards depending on the amount
# of cards in-hand
func reorganizeSelf() ->void:
	# We clear the card as being in-focus if we're asking it to be reorganized
	_focus_completed = false
	match state:
		IN_HAND, FOCUSED_IN_HAND, PUSHED_ASIDE:
			_target_position = _recalculatePosition()
			state = REORGANIZING
	# This second match is  to prevent from changing the state
	# when we're doing fancy movement
	# and we're still in the first part (which is waiting on an animation yield).
	# Instead, we just change the target position transparently,
	# and when the second part of the animation begins
	# it will automatically pick up the right location.
	match state:
		MOVING_TO_CONTAINER:
			_target_position = _recalculatePosition()


# Stops existing card animations then makes sure they're
# properly cleaned-up to allow future animations to play.
func interruptTweening() ->void:
	# This if-logic is there to avoid interrupting animations during fancy_movement,
	# as we want the first part to play always
	# Effectively we're saying if fancy movement is turned on, and you're
	# still doing the first part, don't interrupt
	# If you've finished the first part and are not still in the
	# move to another container movement, then you can interrupt.
	if not cfc.fancy_movement or (cfc.fancy_movement
			and (_fancy_move_second_part
			or state != MOVING_TO_CONTAINER)):
		$Tween.remove_all()
		state = IN_HAND


# Changes card focus (highlighted and put on the focus viewport)
func set_focus(requestedFocus: bool) -> void:
	 # We use an if to avoid performing constant operations in _process
	if $Control/FocusHighlight.visible != requestedFocus and \
			$Control/FocusHighlight.modulate == cfc.FOCUS_HOVER_COLOUR:
		$Control/FocusHighlight.visible = requestedFocus
	if cfc.focus_style: # value 0 means only scaling focus
		if requestedFocus:
			cfc.NMAP.main.focus_card(self)
		else:
			cfc.NMAP.main.unfocus(self)
	# Tokens drawer is an optional node, so we check if it exists
	# We also generally only have tokens on the table
	if $Control.has_node("Tokens"):
		_token_drawer(requestedFocus)
#		if name == "Card" and get_parent() == cfc.NMAP.board:
#			print(requestedFocus)


# Tells us the focus-state of a card
#
# Returns true if card is currently in focus, else false
func get_focus() -> bool:
	var focusState = false
	match state:
		FOCUSED_IN_HAND, FOCUSED_ON_BOARD:
			focusState = true
	return(focusState)


# Adds a token to the card
#
# If the token of that name doesn't exist, it creates it according to the config.
func add_token(token_name : String) -> int:
	var retcode : int
	# If the player requested a token name that has not been defined by the game
	# we return a failure
	if not cfc.TOKENS_MAP.get(token_name, null):
		retcode = _ReturnCode.FAILED
	else:
		var token : Token = get_all_tokens().get(token_name, null)
		# If the token does not exist in the card, we add its node
		# and set it to 1
		if not token:
			token = token_scene.instance()
			token.setup(token_name)
			$Control/Tokens/Drawer/VBoxContainer.add_child(token)
		# If the token node of this name has already been added to the card
		# We just increment it by 1
		else:
			token.count += 1
		# if the drawer has already been opened, we need to make sure
		# the new token name will also appear
		if _is_drawer_open:
			token.expand()
		retcode = _ReturnCode.CHANGED
	return(retcode)


# Removes a token from the card
#
# If the amount of tokens of that type drops to 0, the token icon is also removed.
func remove_token(token_name : String) -> int:
	var retcode : int
	# If the player requested a token name that has not been defined by the game
	# we return a failure
	if not cfc.TOKENS_MAP.get(token_name, null):
		retcode = _ReturnCode.FAILED
	else:
		var token : Token = get_all_tokens().get(token_name, null)
		if not token:
			retcode = _ReturnCode.OK
		else:
			token.count -= 1
			if token.count == 0:
				token.queue_free()
			retcode = _ReturnCode.CHANGED
	return(retcode)


# Returns a dictionary of card tokens on this card.
#
# * Key is the name of the token.
# * Value is the token scene.
func get_all_tokens() -> Dictionary:
	var found_tokens := {}
	for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
		found_tokens[token.name] = token
	return found_tokens


# Returns the token node of the provided name or null if not found.
func get_token(token_name: String) -> Token:
	return(get_all_tokens().get(token_name,null))


# Changes card highlight colour.
func set_highlight(requestedFocus: bool, hoverColour = cfc.HOST_HOVER_COLOUR) -> void:
	$Control/FocusHighlight.visible = requestedFocus
	if requestedFocus:
		$Control/FocusHighlight.modulate = hoverColour
	else:
		$Control/FocusHighlight.modulate = cfc.FOCUS_HOVER_COLOUR


# Returns the Card's index position among other card objects
func get_my_card_index() -> int:
	return get_parent().get_card_index(self)


# Goes through all the potential cards we're currently hovering onto with a card
# or targetting arrow, and highlights the one with the highest index among
# their common parent.
# It also colours the highlight with the provided colour
func highlight_potential_card(colour : Color) -> void:
	for idx in range(0,len(_potential_cards)):
			# The last card in the sorted array is always the highest index
			if idx == len(_potential_cards) - 1:
				_potential_cards[idx].set_highlight(true,colour)
			else:
				_potential_cards[idx].set_highlight(false)


# Will generate a targeting arrow on the card which will follow the mouse cursor.
# The top card hovered over by the mouse cursor will be highlighted
# and will become the target when complete_targeting() is called
func initiate_targeting() -> void:
	_is_targetting = true
	$TargetLine/ArrowHead.visible = true
	$TargetLine/ArrowHead/Area2D.monitoring = true


# Will end the targeting process.
#
# The top card which is hovered (if any) will become the target and inserted
# into the target_card property for future use.
func complete_targeting() -> void:
	if len(_potential_cards) and _is_targetting:
		target_card = _potential_cards.back()
		print("Targeting Demo: ",
				self.name," targeted ",
				target_card.name, " in ",
				target_card.get_parent().name)
	_is_targetting = false
	$TargetLine.clear_points()
	$TargetLine/ArrowHead.visible = false
	$TargetLine/ArrowHead/Area2D.monitoring = false


class CardIndexSorter:
	# Used with sort_custom to find the highest child index among multiple cards
   static func sort_index_ascending(c1: Card, c2: Card):
		   if c1.get_my_card_index() < c2.get_my_card_index():
				   return true
		   return false


# Makes attachments always move with their parent around the board
func _organize_attachments() -> void:
	# We only do this if the parent is still on the board
	if get_parent() == cfc.NMAP.board:
		for card in attachments:
			# We use the index of the attachment among other attachments
			# to figure out its index and placement
			var attach_index = attachments.find(card)
			if attach_index:
				# if the card is not the first attachment to this host
				# Then we make sure that each subsequent card is higher
				# in the node hierarchy than its parent
				# This will make latter cards draw below the others
				if card.get_index() > attachments[attach_index - 1].get_index():
					get_parent().move_child(card,
							attachments[attach_index - 1].get_index())
			# If the card if the first for its host, we need to make sure
			# it is higher in the hierarchy than the host
			elif card.get_index() > self.get_index():
				get_parent().move_child(card,self.get_index())
			# We don't want to try and move it if it's still tweening.
			# But if it isn't, we make sure it always follows its parent
			if not card.get_node('Tween').is_active() and \
					card.state == ON_PLAY_BOARD:
				card.global_position = global_position + \
						Vector2(0,(attach_index + 1) \
						* $Control.rect_size.y \
						* cfc.ATTACHMENT_OFFSET)


# We're using this helper function, to allow our mouse-position relevant code
# to work during integration testing
# Returns either the adjusted global mouse position
# or a fake mouse position provided by integration testing
func _determine_global_mouse_pos() -> Vector2:
	var mouse_position
	var zoom = Vector2(1,1)
	# We have to do the below offset hack due to godotengine/godot#30215
	# This is caused because we're using a viewport node and
	# scaling the game in full-creen.
	if get_viewport().has_node("Camera2D"):
		zoom = get_viewport().get_node("Camera2D").zoom
	var offset_mouse_position = \
			get_tree().current_scene.get_global_mouse_position() \
			- get_viewport_transform().origin
	offset_mouse_position *= zoom
	#var scaling_offset = get_tree().get_root().get_node('Main').get_viewport().get_size_override() * OS.window_size
	if cfc.UT: mouse_position = cfc.NMAP.board._UT_mouse_position
	else: mouse_position = offset_mouse_position
	return mouse_position



# Returns the global mouse position but ensures it does not exit the
# viewport limits when including the card rect
#
# Returns the adjusted global_mouse_position
func _determine_board_position_from_mouse() -> Vector2:
	var targetpos: Vector2 = _determine_global_mouse_pos()
	if targetpos.x + $Control.rect_size.x * scale.x >= get_viewport().size.x:
		targetpos.x = get_viewport().size.x - $Control.rect_size.x * scale.x
	if targetpos.x < 0:
		targetpos.x = 0
	if targetpos.y + $Control.rect_size.y * scale.y >= get_viewport().size.y:
		targetpos.y = get_viewport().size.y - $Control.rect_size.y * scale.y
	if targetpos.y < 0:
		targetpos.y = 0
	return targetpos


# This function figures out where on the table a card should be placed
# based on the mouse position
# It takes extra care not to drop the card outside viewport margins
func _determine_target_position_from_mouse() -> void:
	_target_position = _determine_board_position_from_mouse()
	# The below ensures the card doesn't leave the viewport dimentions
	if _target_position.x + $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x \
			> get_viewport().size.x:
		_target_position.x = get_viewport().size.x \
				- $Control.rect_size.x \
				* cfc.PLAY_AREA_SCALE.x
	if _target_position.y + $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y \
			> get_viewport().size.y:
		_target_position.y = get_viewport().size.y \
				- $Control.rect_size.y \
				* cfc.PLAY_AREA_SCALE.y


# Instructs the card to move aside for another card enterring focus
func _pushAside(targetpos: Vector2) -> void:
	interruptTweening()
	_target_position = targetpos
	state = PUSHED_ASIDE


# Recalculates the position of the current card object
# based on how many cards we have already in hand and its index among them
# Returns the local position the card should have in the hand
func _recalculatePosition() ->Vector2:
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	# The number of cards currently in hand
	var hand_size: int = get_parent().get_card_count()
	# The maximum of horizontal pixels we want the cards to take
	# We simply use the size of the parent control container we've defined in
	# the node settings
	var max_hand_size_width: float = get_parent().get_node('Control').rect_size.x
	# The maximum distance between cards
	# We base it on the card width to allow it to work with any card-size.
	var card_gap_max: float = $Control.rect_size.x * 1.1
	# The minimum distance between cards
	# (less than card width means they start overlapping)
	var card_gap_min: float = $Control.rect_size.x/2
	# The current distance between cards.
	# It is inversely proportional to the amount of cards in hand
	var cards_gap: float = max(min((max_hand_size_width
			- $Control.rect_size.x/2)
			/ hand_size, card_gap_max), card_gap_min)
	# The current width of all cards in hand together
	var hand_width: float = (cards_gap * (hand_size-1)) + $Control.rect_size.x
	# The following just create the vector position to place this specific card
	# in the playspace.
	card_position_x = (max_hand_size_width/2
			- hand_width/2
			+ cards_gap
			* get_my_card_index())
	# Since our control container has the same size as the cards,we start from 0
	# and just offset the card if we want it higher or lower.
	card_position_y = 0
	return Vector2(card_position_x,card_position_y)


# Pick up a card to drag around with the mouse.
func _start_dragging() -> void:
	# When dragging we want the dragged card to always be drawn above all else
	z_index = 99
	# We have use parent viewport to calculate global_position
	# due to godotengine/godot#30215
	# This is caused because we're using a viewport node and scaling the game
	# in full-creen.
	if not cfc.UT:
		if ProjectSettings.get("display/window/stretch/mode") != 'disabled':
			get_tree().current_scene.get_viewport().warp_mouse(global_position)
		# However the above messes things if we don't have stretch mode,
		# so we ignore it then
		else:
			get_viewport().warp_mouse(global_position)
	state = DRAGGED
	if get_parent() in cfc.hands:
		# While we're dragging the card from hand, we want the other cards
		# to move to their expected position in hand
		for c in get_parent().get_all_cards():
			if c != self:
				c.interruptTweening()
				c.reorganizeSelf()


# Determines the state a card should have,
# based on the card's container grouping.
#
# This is needed because some states are generic
# and don't always know the state the card should be afterwards
func _determine_idle_state() -> void:
	if get_parent() in cfc.hands:
		state = IN_HAND
	# The extra if is in case the ViewPopup is currently active when the card
	# is being moved into the container
	elif get_parent() in cfc.piles or "CardPopUpSlot" in get_parent().name:
		state = IN_PILE
	else:
		state = ON_PLAY_BOARD


# Makes the card change visibility nicely
func _tween_interpolate_visibility(visibility: float, time: float) -> void:
	# We only want to do something if we're actually doing something
	if modulate[3] != visibility:
		$Tween.interpolate_property(self,'modulate',
			modulate, Color(1, 1, 1, visibility), time,
			Tween.TRANS_QUAD, Tween.EASE_OUT)


# Clears all attachment/hosting status.
# It is typically called when a card is removed from the table
func _clear_attachment_status() -> void:
	if current_host_card:
		current_host_card.attachments.erase(self)
		current_host_card = null
	for card in attachments:
		card.current_host_card = null
		# Attachments typically follow their parents to the same container
		card.move_to(get_parent())
		# We do a small wait to make the attachment drag look nicer
		yield(get_tree().create_timer(0.1), "timeout")

	attachments.clear()


# Detects when the mouse is still hovering over the buttons area.
#
# We need to detect this extra, because the buttons restart event propagation.
#
# This means that the Control parent, will send a mouse_exit signal
# when the mouse enter a button rect
# which will make the buttons disappear again.
#
# So we make sure buttons stay visible while the mouse is on top.
#
# This is all necessary as a workaround for godotengine/godot#16854
#
# Returns true if the mouse is hovering over the buttons, else false
func _are_buttons_hovered() -> bool:
	var ret = false
	if (_determine_global_mouse_pos().x
			>= $Control/ManipulationButtons.rect_global_position.x and
			_determine_global_mouse_pos().y
			>= $Control/ManipulationButtons.rect_global_position.y and
			_determine_global_mouse_pos().x
			<= $Control/ManipulationButtons.rect_global_position.x
			+ $Control/ManipulationButtons.rect_size.x and
			_determine_global_mouse_pos().y
			<= $Control/ManipulationButtons.rect_global_position.y
			+ $Control/ManipulationButtons.rect_size.y):
		ret = true
	return(ret)


# Detects when the mouse is still hovering over the tokens area.
#
# We need to detect this extra, for the same reasons as the targetting buttons
# If we do not, the buttons continuously try to open and close.
#
# Returns true if the mouse is hovering over the token drawer, else false
func _is_drawer_hovered() -> bool:
	var ret = false
	if (_determine_global_mouse_pos().x
			>= $Control/Tokens/Drawer.rect_global_position.x and
			_determine_global_mouse_pos().y
			>= $Control/Tokens/Drawer.rect_global_position.y and
			_determine_global_mouse_pos().x
			<= $Control/Tokens/Drawer.rect_global_position.x
			+ $Control/Tokens/Drawer.rect_size.x and
			_determine_global_mouse_pos().y
			<= $Control/Tokens/Drawer.rect_global_position.y
			+ $Control/Tokens/Drawer.rect_size.y):
		ret = true
	return(ret)


# Detects when the mouse is still hovering over the card
#
# We need to detect this extra, for the same reasons as the targetting buttons
# In case the mouse was hovering over the tokens area and just exited
#
# Returns true if the mouse is hovering over the card, else false
func _is_card_hovered() -> bool:
	var ret = false
	if (_determine_global_mouse_pos().x
			>= $Control.rect_global_position.x and
			_determine_global_mouse_pos().y
			>= $Control.rect_global_position.y and
			_determine_global_mouse_pos().x
			<= $Control.rect_global_position.x
			+ $Control.rect_size.x and
			_determine_global_mouse_pos().y
			<= $Control.rect_global_position.y
			+ $Control.rect_size.y):
		ret = true
	#print(ret)
	return(ret)


# Flips the visible parts of the card control nodes
# so that the correct Panel (Card Back or Card Front) and children is visible
#
# It also pretends to flip the highlight, otherwise it looks fake.
func _flip_card(to_invisible: Control, to_visible: Control, instant := false) -> void:
	if instant:
		to_visible.visible = true
		to_visible.rect_scale.x = 1
		to_visible.rect_position.x = 0
		to_invisible.visible = false
		to_invisible.rect_scale.x = 0
		to_invisible.rect_position.x = to_visible.rect_size.x/2
	# When dupe cards in focus viewport are created, they have parent == null
	# This causes them to raise an error trying to create a tween
	# So we skip that.
	elif get_parent() == null:
		pass
	else:
		# We clear existing tweens to avoid a deadlocks
		for n in [$Control/Front, $Control/Back, $Control/FocusHighlight]:
			$Control/FlipTween.remove(n,'rect_scale')
			$Control/FlipTween.remove(n,'rect_position')
		$Control/FlipTween.interpolate_property(to_invisible,'rect_scale',
				to_invisible.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		$Control/FlipTween.interpolate_property(to_invisible,'rect_position',
				to_invisible.rect_position, Vector2(
				to_invisible.rect_size.x/2,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		$Control/FlipTween.interpolate_property($Control/FocusHighlight,'rect_scale',
				$Control/FocusHighlight.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		# The highlight is larger than the card size, but also offet a big
		# so that it's still centered. This way its borders only extend
		# over the card borders. We need to offest to the right location.
		$Control/FlipTween.interpolate_property($Control/FocusHighlight,'rect_position',
				$Control/FocusHighlight.rect_position, Vector2(
				($Control/FocusHighlight.rect_size.x-3)/2,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		$Control/FlipTween.start()
		yield($Control/FlipTween, "tween_all_completed")
		to_visible.visible = true
		to_invisible.visible = false
		$Control/FlipTween.interpolate_property(to_visible,'rect_scale',
				to_visible.rect_scale, Vector2(1,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Control/FlipTween.interpolate_property(to_visible,'rect_position',
				to_visible.rect_position, Vector2(0,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Control/FlipTween.interpolate_property($Control/FocusHighlight,'rect_scale',
				$Control/FocusHighlight.rect_scale, Vector2(1,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Control/FlipTween.interpolate_property($Control/FocusHighlight,'rect_position',
				$Control/FocusHighlight.rect_position, Vector2(-3,-3), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Control/FlipTween.start()

# Draws a curved arrow, from the center of a card, to the mouse pointer
func _draw_targeting_arrow() -> void:
	# This variable calculates the card center's position on the whole board
	var centerpos = global_position + $Control.rect_size/2*scale
	# We want the line to be drawn anew every frame
	$TargetLine.clear_points()
	# The final position is the mouse position,
	# but we offset it by the position of the card center on the map
	var final_point =  _determine_global_mouse_pos() - (position + $Control.rect_size/2)
	var curve = Curve2D.new()
#		var middle_point = centerpos + (get_global_mouse_position() - centerpos)/2
#		var middle_dir_to_vpcenter = middle_point.direction_to(get_viewport().size/2)
#		var offmid = middle_point + middle_dir_to_vpcenter * 50
	# Our starting point has to be translated to the local position of the Line2D node
	# The out control point is the direction to the screen center,
	# with a magnitude that I found via trial and error to look good
	curve.add_point($TargetLine.to_local(centerpos),
			Vector2(0,0),
			centerpos.direction_to(get_viewport().size/2) * 75)
#		curve.add_point($TargetLine.to_local(offmid), Vector2(0,0), Vector2(0,0))
	# Our end point also has to be translated to the local position of the Line2D node
	# The in control point is likewise the direction to the screen center
	# with a magnitude that I found via trial and error to look good
	curve.add_point($TargetLine.to_local(position +
			$Control.rect_size/2 + final_point),
			Vector2(0, 0), Vector2(0, 0))
	# Finally we use the Curve2D object to get the points which will be drawn
	# by our lined2D
	$TargetLine.set_points(curve.get_baked_points())
	# We place the arrowhead to start from the last point in the line2D
	$TargetLine/ArrowHead.position = $TargetLine.get_point_position(
			$TargetLine.get_point_count( ) - 1)
	# We delete the last 3 Line2D points, because the arrowhead will
	# be covering those areas
	for _del in range(1,3):
		$TargetLine.remove_point($TargetLine.get_point_count( ) - 1)
	# We setup the angle the arrowhead is pointing by finding the angle of
	# the last point on the line towards the mouse position
	$TargetLine/ArrowHead.rotation = $TargetLine.get_point_position(
				$TargetLine.get_point_count( ) - 1).direction_to(
				$TargetLine.to_local(
				position + $Control.rect_size/2 + final_point)).angle()


# Triggers the looping card back pulse
# The pulse increases and decreases the brightness of the glow
func _start_pulse():
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists
	if $Control/Back.has_node('Pulse'):
		$Control/Back/Pulse.interpolate_property($Control/Back,'modulate',
				_pulse_values[0], _pulse_values[1], 2,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Control/Back/Pulse.start()


# Disables the looping card back pulse
func _stop_pulse():
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists
	if $Control/Back.has_node('Pulse'):
		$Control/Back/Pulse.remove_all()
		$Control/Back.modulate = Color(1,1,1)


# A rudimentary Finite State Engine for cards.
#
# Makes sure that when a card is in a specific state while
# its position, highlights, scaling and so on, stay as expected
func _process_card_state() -> void:
	match state:
		IN_HAND:
			set_focus(false)
		FOCUSED_IN_HAND:
			# Used when card is focused on by the mouse hovering over it.
			set_focus(true)
			if not $Tween.is_active() and \
					not _focus_completed and \
					cfc.focus_style != cfc.FocusStyle.VIEWPORT:
				var expected_position: Vector2 = _recalculatePosition()
				# We figure out our neighbours by their index
				var neighbours := []
				for neighbour_index_diff in [-2,-1,1,2]:
					var hand_size: int = get_parent().get_card_count()
					var neighbour_index: int = \
							get_my_card_index() + neighbour_index_diff
					if neighbour_index >= 0 and neighbour_index <= hand_size - 1:
						var neighbour_card: Card = get_parent().get_card(neighbour_index)
						# Neighbouring cards are pushed to the side to allow
						# the focused card to not be overlapped
						# The amount they're pushed is relevant to
						# how close neighbours they are.
						# Closest neighbours (1 card away) are pushed more
						# than further neighbours.
						neighbour_card._pushAside(neighbour_card._recalculatePosition()
								+ Vector2(neighbour_card.get_node('Control').rect_size.x
									/ neighbour_index_diff
									* cfc.NEIGHBOUR_PUSH,0))
						neighbours.append(neighbour_card)
				for c in get_parent().get_all_cards():
					if not c in neighbours and c != self:
						c.interruptTweening()
						c.reorganizeSelf()
				# When zooming in, we also want to move the card higher,
				# so that it's not under the screen's bottom edge.
				_target_position = expected_position \
						- Vector2($Control.rect_size.x \
						* 0.25,$Control.rect_size.y \
						* 0.5 + cfc.NMAP.hand.bottom_margin)
				# We make sure to remove other tweens of the same type
				# to avoid a deadlock
				$Tween.remove(self,'position')
				$Tween.interpolate_property(self,'position',
						expected_position, _target_position, 0.3,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.remove(self,'scale')
				$Tween.interpolate_property(self,'scale',
						scale, Vector2(1.5,1.5), 0.3,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.start()
				_focus_completed = true
				# We don't change state yet, only when the focus is removed
				# from this card
		MOVING_TO_CONTAINER:
			# Used when moving card between places
			# (i.e. deck to hand, hand to discard etc)
			set_focus(false)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if cfc.fancy_movement:
					# The below calculations figure out
					# the intermediate position as a spot,
					# offset towards the viewport center by an amount proportional
					# to distance from the viewport center.
					# (My math is not the best so there's probably a more elegant formula)
					var direction_x: int = -1
					var direction_y: int = -1
					if get_parent() != cfc.NMAP.board:
						# We determine its center position on the viewport
						var controlNode_center_position := \
								Vector2(global_position + $Control.rect_size/2)
						# We then direct this position towards the viewport center
						# If we are to the left/top of viewport center,
						# we offset towards the right/bottom (+offset)
						# If we are to the right/bottom of viewport center,
						# we offset towards the left/top (-offset)
						if controlNode_center_position.x < get_viewport().size.x/2:
							direction_x = 1
						if controlNode_center_position.y < get_viewport().size.y/2:
							direction_y = 1
						# The offset amount if calculated by creating a multiplier
						# based on the distance of our target container
						# from the viewport center
						# The further away they are, the more the intermediate point
						# moves towards the screen center
						# We always offset by percentages of the card size to
						# be consistent in case the card size changes
						var offset_x = (abs(controlNode_center_position.x
								- get_viewport().size.x/2)) / 250 * $Control.rect_size.x
						var offset_y = (abs(controlNode_center_position.y
								- get_viewport().size.y/2)) / 250 * $Control.rect_size.y
						var inter_x = controlNode_center_position.x \
								+ direction_x * offset_x
						var inter_y = controlNode_center_position.y \
								+ direction_y * offset_y
						# We calculate the position we want the card to move
						# on the viewport
						# then we translate that position to the local coordinates
						# within the parent control node
						#intermediate_position = Vector2(inter_x,inter_y)
						intermediate_position = Vector2(inter_x,inter_y)
					# The board doesn't have a node2d host container.
					# Instead we use directly the viewport coords.
					else:
						intermediate_position = get_viewport().size/2
					if not scale.is_equal_approx(Vector2(1,1)):
						$Tween.remove(self,'scale')
						$Tween.interpolate_property(self,'scale',
								scale, Vector2(1,1), 0.4,
								Tween.TRANS_CUBIC, Tween.EASE_OUT)
					$Tween.remove(self,'global_position')
					$Tween.interpolate_property(self,'global_position',
							global_position, intermediate_position, 0.5,
							Tween.TRANS_BACK, Tween.EASE_IN_OUT)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					_tween_stuck_time = 0
					_fancy_move_second_part = true
				# We need to check again, just in case it's been reorganized instead.
				if state == MOVING_TO_CONTAINER:
					$Tween.remove(self,'position')
					$Tween.interpolate_property(self,'position',
							position, _target_position, 0.35,
							Tween.TRANS_SINE, Tween.EASE_IN_OUT)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					_determine_idle_state()
				_fancy_move_second_part = false
		REORGANIZING:
			# Used when reorganizing the cards in the hand
			set_focus(false)
			if not $Tween.is_active():
				$Tween.remove(self,'position') #
				$Tween.interpolate_property(self,'position',
						position, _target_position, 0.4,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				if not scale.is_equal_approx(Vector2(1,1)):
					$Tween.remove(self,'scale')
					$Tween.interpolate_property(self,'scale',
							scale, Vector2(1,1), 0.4,
							Tween.TRANS_CUBIC, Tween.EASE_OUT)
				_tween_interpolate_visibility(1,0.4)
				$Tween.start()
				state = IN_HAND
		PUSHED_ASIDE:
			# Used when card is being pushed aside due to the focusing of a neighbour.
			set_focus(false)
			if not $Tween.is_active() and \
					not position.is_equal_approx(_target_position):
				$Tween.remove(self,'position')
				$Tween.interpolate_property(self,'position',
						position, _target_position, 0.3,
						Tween.TRANS_QUART, Tween.EASE_IN)
				if not scale.is_equal_approx(Vector2(1,1)):
					$Tween.remove(self,'scale')
					$Tween.interpolate_property(self,'scale',
							scale, Vector2(1,1), 0.3,
							Tween.TRANS_QUART, Tween.EASE_IN)
				$Tween.start()
				# We don't change state yet,
				# only when the focus is removed from the neighbour
		DRAGGED:
			# Used when the card is dragged around the game with the mouse
			if (not $Tween.is_active() and
				not scale.is_equal_approx(cfc.card_scale_while_dragging) and
				get_parent() != cfc.NMAP.board):
				$Tween.remove(self,'scale')
				$Tween.interpolate_property(self,'scale',
						scale, cfc.card_scale_while_dragging, 0.2,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Tween.start()
			# We need to capture the mouse cursos in the window while dragging
			# because if the player drags the cursor outside the window and unclicks
			# The control will not receive the mouse input
			# and this will stay dragging forever
			if not cfc.UT: Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			$Control.set_default_cursor_shape(Input.CURSOR_CROSS)
			# We set the card to be centered on the mouse cursor to allow
			# the player to properly understand where it will go once dropped.
			global_position = _determine_board_position_from_mouse()# - $Control.rect_size/2 * scale
			_organize_attachments()
			# We want to keep the token drawer closed during movement
			if _is_drawer_open:
				_token_drawer(false)
		ON_PLAY_BOARD:
			# Used when the card is idle on the board
			set_focus(false)
			if not $Tween.is_active() and \
					not scale.is_equal_approx(cfc.PLAY_AREA_SCALE):
				$Tween.remove(self,'scale')
				$Tween.interpolate_property(self,'scale',
						scale, cfc.PLAY_AREA_SCALE, 0.3,
						Tween.TRANS_SINE, Tween.EASE_OUT)
				$Tween.start()
			# This tween hides the container manipulation buttons
			if not $Control/ManipulationButtons/Tween.is_active() and \
					$Control/ManipulationButtons.modulate[3] != 0:
				# We always make sure to clean tweening conflicts
				$Control/ManipulationButtons/Tween.remove_all()
				$Control/ManipulationButtons/Tween.interpolate_property(
						$Control/ManipulationButtons,'modulate',
						$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Control/ManipulationButtons/Tween.start()
			_organize_attachments()
		DROPPING_TO_BOARD:
			# Used when dropping the cards to the table
			# When dragging the card, the card is slightly behind the mouse cursor
			# so we tween it to the right location
			if not $Tween.is_active():
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
#				_target_position = _determine_board_position_from_mouse()
#				# The below ensures the card doesn't leave the viewport dimentions
#				if _target_position.x + $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x > get_viewport().size.x:
#					_target_position.x = get_viewport().size.x - $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x
#				if _target_position.y + $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y > get_viewport().size.y:
#					_target_position.y = get_viewport().size.y - $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y
				$Tween.interpolate_property(self,'position',
						position, _target_position, 0.25,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				# We want cards on the board to be slightly smaller than in hand.
				if not scale.is_equal_approx(cfc.PLAY_AREA_SCALE):
					$Tween.remove(self,'scale')
					$Tween.interpolate_property(self,'scale',
							scale, cfc.PLAY_AREA_SCALE, 0.5,
							Tween.TRANS_BOUNCE, Tween.EASE_OUT)
				$Tween.start()
				state = ON_PLAY_BOARD
		FOCUSED_ON_BOARD:
			# Used when card is focused on by the mouse hovering over it while it is on the board.
			# The below tween shows the container manipulation buttons when you hover over them
			set_focus(true)
			if not $Control/ManipulationButtons/Tween.is_active() and \
					$Control/ManipulationButtons.modulate[3] != 1:
				$Control/ManipulationButtons/Tween.remove_all()
				$Control/ManipulationButtons/Tween.interpolate_property(
						$Control/ManipulationButtons,'modulate',
						$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Control/ManipulationButtons/Tween.start()
			# We don't change state yet, only when the focus is removed from this card
		DROPPING_INTO_PILE:
			# Used when dropping the cards into a container (Deck, Discard etc)
			set_focus(false)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if cfc.fancy_movement:
					intermediate_position = get_parent().position - \
							Vector2(0,$Control.rect_size.y*1.1)
					$Tween.remove(self,'position')
					$Tween.interpolate_property(self,'position',
							position, intermediate_position, 0.25,
							Tween.TRANS_CUBIC, Tween.EASE_OUT)
					yield($Tween, "tween_all_completed")
					if not scale.is_equal_approx(cfc.PLAY_AREA_SCALE):
						$Tween.remove(self,'scale')
						$Tween.interpolate_property(self,'scale',
								scale, Vector2(1,1), 0.5,
								Tween.TRANS_BOUNCE, Tween.EASE_OUT)
					$Tween.start()
					_fancy_move_second_part = true
				else:
					intermediate_position = get_parent().position
				$Tween.remove(self,'position')
				$Tween.interpolate_property(self,'position',
						intermediate_position, get_parent().position, 0.35,
						Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				$Tween.start()
				_determine_idle_state()
				_fancy_move_second_part = false
				state = IN_PILE
		IN_PILE:
			set_focus(false)
		FOCUSED_IN_POPUP:
			# Used when the card is displayed in the popup grid container
			set_focus(true)


# Reveals or Hides the token drawer
#
# The drawer will not appear while another animation is ongoing
# and it will appear only while the card is on the board.
func _token_drawer(drawer_state := true) -> void:
	# I use these vars to avoid writing it all the time and to improve readability
	var tween := $Control/Tokens/Tween
	var td := $Control/Tokens/Drawer
	# We want to keep the drawer closed during the flip and movement
	if not tween.is_active() and \
			not $Control/FlipTween.is_active() and \
			not $Tween.is_active():
		# We don't open the drawer if we don't have any tokens at all
		if drawer_state == true and \
				$Control/Tokens/Drawer/VBoxContainer.get_child_count() and \
				(state == ON_PLAY_BOARD or state == FOCUSED_ON_BOARD):
			if not _is_drawer_open:
				_is_drawer_open = true
				# To avoid tween deadlocks
				tween.remove_all()
				tween.interpolate_property(
						td,'rect_position', td.rect_position,
						Vector2($Control.rect_size.x,td.rect_position.y),
						0.3, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				# We make all tokens display names
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.expand()
				# Normally the drawer is invisible. We make it visible now
				$Control/Tokens/Drawer.self_modulate[3] = 1
				tween.start()
				# We need to make our tokens appear on top of other cards on the table
				$Control/Tokens.z_index = 99
		else:
			if _is_drawer_open:
				tween.remove_all()
				tween.interpolate_property(
						td,'rect_position', td.rect_position,
						Vector2($Control.rect_size.x - 35,
						td.rect_position.y),
						0.2, Tween.TRANS_ELASTIC, Tween.EASE_IN)
				tween.start()
				# We want to consider the drawer closed
				# only when the animation finished
				# Otherwise it might start to open immediately again
				yield(tween, "tween_all_completed")
				# When it's closed, we hide token names
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.retract()
				$Control/Tokens/Drawer.self_modulate[3] = 0
				_is_drawer_open = false
				$Control/Tokens.z_index = 0

func change_group(_group_name):
	var built_in_group = ["idle_process","idle_process_internal","physics_process","physics_process_internal",]
	for group_name in get_groups():
		if not (group_name  in built_in_group):
			remove_from_group(group_name)
	add_to_group(_group_name)