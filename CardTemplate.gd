extends Node2D
class_name Card
# This class is meant to be used as the basis for your card scripting
# Simply make your card scripts extend this class and you'll have all the provided scripts available
# If your card node type is not control, make sure you change the extends type above

## Load Config
var tween_stuck_time = 0
onready var bottom_margin: float = $Control.rect_size.y * cfc_config.bottom_margin_multiplier
# warning-ignore:unused_class_variable
# We export this variable to the editor to allow us to add scripts to each card object directly instead of only via code.
export var scripts := [{'name':'','args':['',0]}]
enum{ # Finite state engine for all posible states a card might be in
	  # This simply is a way to refer to the values with a human-readable name.
	InHand					#0
	FocusedInHand			#1
	MovingToContainer		#2
	Reorganizing			#3
	PushedAside				#4
	Dragged					#5
	DroppingToBoard			#6
	OnPlayBoard				#7
	FocusedOnBoard			#8
	DroppingIntoPile 		#9
	InPile					#10
}
var state := InPile # Starting state for each card
var target_position: Vector2 # Used for animating the card
var focus_completed: bool = false # Used to avoid the focus animation repeating once it's completed.
var fancy_move_second_part := false # We use this to know at which stage of fancy movement this is.
var dragging_attempted := true
signal card_dropped(card) # No support for static typing in signals yet (godotengine/godot#26045)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "_on_Card_mouse_entered")
	# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "_on_Card_mouse_exited")
	# warning-ignore:return_value_discarded
	connect("input_event", self, "_on_Card_gui_input")
	# warning-ignore:return_value_discarded
	for node in cfc_config.piles + cfc_config.hands:
		# warning-ignore:return_value_discarded
		connect("card_dropped", node, "_on_dropped_card")
	connect("card_dropped", cfc_config.NMAP.board, "_on_dropped_card")

func card_action() -> void:
	pass

func _process(delta) -> void:
	# A basic finite state engine
	if $Tween.is_active(): # Debug code for catch potential Tween deadlocks
		tween_stuck_time += delta
		if tween_stuck_time > 2 and int(fmod(tween_stuck_time,3)) == 2 :
			print("Tween Stuck for ",tween_stuck_time,"seconds. Reports leftover runtime: ",$Tween.get_runtime ( ))
			$Tween.remove_all()
			tween_stuck_time = 0
	else:
		tween_stuck_time = 0
	match state:
		InHand:
			pass
		FocusedInHand:
			# Used when card is focused on by the mouse hovering over it.
			if not $Tween.is_active() and not focus_completed:
				var expected_position: Vector2 = _recalculatePosition()
				# We figure out our neighbours by their index
				var neighbours := []
				for neighbour_index_diff in [-2,-1,1,2]:
					var hand_size: int = get_parent().get_card_count()
					var neighbour_index: int = get_my_card_index() + neighbour_index_diff
					if neighbour_index >= 0 and neighbour_index <= hand_size - 1:
						var neighbour_card: Card = get_parent().get_card(neighbour_index)
						# Neighbouring cards are pushed to the side to allow the focused card to not be overlapped
						# The amount they're pushed is relevant to how close neighbours they are.
						# Closest neighbours (1 card away) are pushed more than further neighbours.
						neighbour_card.pushAside(neighbour_card._recalculatePosition() + Vector2(neighbour_card.get_node('Control').rect_size.x/neighbour_index_diff * cfc_config.neighbour_push,0))
						neighbours.append(neighbour_card)
				for c in get_parent().get_all_cards():
					if not c in neighbours and c != self:
						c.interruptTweening()
						c.reorganizeSelf()
				# When zooming in, we also want to move the card higher, so that it's not under the screen's bottom edge.
				target_position = expected_position - Vector2($Control.rect_size.x * 0.25,$Control.rect_size.y * 0.5 + bottom_margin)
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'position',
					expected_position, target_position, 0.3,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'scale',
					scale, Vector2(1.5,1.5), 0.3,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.start()
				focus_completed = true
				# We don't change state yet, only when the focus is removed from this card
		MovingToContainer:
			# Used when moving card between places (i.e. deck to hand, hand to discard etc)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if cfc_config.fancy_movement:
					# The below calculations figure out the intermediate position as a spot,
					# offset towards the viewport center by an amount proportional to distance from the viewport center.
					# (My math is not the best so there's probably a more elegant formula)
					var direction_x: int = -1
					var direction_y: int = -1
					if get_parent() != cfc_config.NMAP.board:
						# We determine its center position on the viewport
						var controlNode_center_position := Vector2(global_position + $Control.rect_size/2)
						# We then direct this position towards the viewport center
						# If we are to the left/top of viewport center, we offset towards the right/bottom (+offset)
						# If we are to the right/bottom of viewport center, we offset towards the left/top (-offset)
						if controlNode_center_position.x < get_viewport().size.x/2: direction_x = 1
						if controlNode_center_position.y < get_viewport().size.y/2: direction_y = 1
						# The offset amount if calculated by creating a multiplier based on the distance of our target container from the viewport center
						# The further away they are, the more the intermediate point moves towards the screen center
						# We always offset by percentages of the card size to be consistent in case the card size changes
						var offset_x = (abs(controlNode_center_position.x - get_viewport().size.x/2)) / 250 * $Control.rect_size.x
						var offset_y = (abs(controlNode_center_position.y - get_viewport().size.y/2)) / 250 * $Control.rect_size.y
						var inter_x = controlNode_center_position.x + direction_x * offset_x
						var inter_y = controlNode_center_position.y + direction_y * offset_y
						# We calculate the position we want the card to move on the viewport
						# then we translate that position to the local coordinates within the parent control node
						#intermediate_position = Vector2(inter_x,inter_y)
						intermediate_position = Vector2(inter_x,inter_y)
					else: #  The board doesn't have a node2d host container. Instead we use directly the viewport coords.
						intermediate_position = get_viewport().size/2
					if not scale.is_equal_approx(Vector2(1,1)):
						$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
						$Tween.interpolate_property(self,'scale',
							scale, Vector2(1,1), 0.4,
							Tween.TRANS_CUBIC, Tween.EASE_OUT)
					$Tween.remove(self,'global_position') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'global_position',
						global_position, intermediate_position, 0.5,
						Tween.TRANS_BACK, Tween.EASE_IN_OUT)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					tween_stuck_time = 0
					fancy_move_second_part = true
				if state == MovingToContainer: # We need to check again, just in case it's been reorganized instead.
					$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'position',
						position, target_position, 0.35,
						Tween.TRANS_SINE, Tween.EASE_IN_OUT)
					$Tween.start()
					determine_idle_state()
				fancy_move_second_part = false
		Reorganizing:
			# Used when reorganizing the cards in the hand
			if not $Tween.is_active():
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'position',
					position, target_position, 0.4,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				if not scale.is_equal_approx(Vector2(1,1)):
					$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'scale',
						scale, Vector2(1,1), 0.4,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				tween_interpolate_visibility(1,0.4)
				$Tween.start()
				state = InHand
		PushedAside:
			# Used when card is being pushed aside due to the focusing of a neighbour.
			if not $Tween.is_active() and not position.is_equal_approx(target_position):
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'position',
					position, target_position, 0.3,
					Tween.TRANS_QUART, Tween.EASE_IN)
				if not scale.is_equal_approx(Vector2(1,1)):
					$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'scale',
						scale, Vector2(1,1), 0.3,
						Tween.TRANS_QUART, Tween.EASE_IN)
				$Tween.start()
				# We don't change state yet, only when the focus is removed from the neighbour
		Dragged:
			# Used when the card is dragged around the game with the mouse
			if not $Tween.is_active() and not scale.is_equal_approx(Vector2(0.4,0.4)):
				$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'scale',
					scale, Vector2(0.4,0.4), 0.2,
					Tween.TRANS_SINE, Tween.EASE_IN)
				$Tween.start()
				#z_as_relative = false
				#z_index = 99
			# The position of the card object is relevant to the parent only.
			# To make the card start moving from the right spot, we need to adjust the global mouse pos
			# To where it would be in respect to the card's parent
			position = get_parent().to_local(_determine_board_position_from_mouse())
		OnPlayBoard:
			# Used when the card is idle on the board
			if not $Tween.is_active() and not scale.is_equal_approx(cfc_config.play_area_scale):
				$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'scale',
					scale, cfc_config.play_area_scale, 0.3,
					Tween.TRANS_SINE, Tween.EASE_OUT)
			$Tween.start()
		FocusedOnBoard:
			# We check if the drag is ongoing here so that we can focus on a card even after the drag finished
			if not cfc_config.card_drag_ongoing and not $Tween.is_active():
				pass
#				if not scale.is_equal_approx(Vector2(1.2,1.2)):
#					$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
#					$Tween.interpolate_property(self,'scale',
#						scale, Vector2(1.2,1.2), 0.3,
#						Tween.TRANS_SINE, Tween.EASE_OUT)
#				$Tween.start()
		DroppingToBoard:
			# Used when dropping the cards to the table
			# When dragging the card, the card is slightly behind the mouse cursor
			# so we tween it to the right location
			if not $Tween.is_active():
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'position',
					position, _determine_board_position_from_mouse(), 0.25,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				# We want cards on the board to be slightly smaller than in hand.
				if not scale.is_equal_approx(cfc_config.play_area_scale):
					$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'scale',
						scale, cfc_config.play_area_scale, 0.5,
						Tween.TRANS_BOUNCE, Tween.EASE_OUT)
				$Tween.start()
				state = OnPlayBoard
		DroppingIntoPile:
			# Used when dropping the cards into a container (Deck, Discard etc)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if cfc_config.fancy_movement:
					intermediate_position = get_parent().position - Vector2(0,$Control.rect_size.y*1.1)
					$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
					$Tween.interpolate_property(self,'position',
						position, intermediate_position, 0.25,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
					yield($Tween, "tween_all_completed")
					if not scale.is_equal_approx(cfc_config.play_area_scale):
						$Tween.remove(self,'scale') # We make sure to remove other tweens of the same type to avoid a deadlock
						$Tween.interpolate_property(self,'scale',
							scale, Vector2(1,1), 0.5,
							Tween.TRANS_BOUNCE, Tween.EASE_OUT)
					$Tween.start()
					fancy_move_second_part = true
				else:
					intermediate_position = get_parent().position
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
				$Tween.interpolate_property(self,'position',
					intermediate_position, get_parent().position, 0.35,
					Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				$Tween.start()
				determine_idle_state()
				fancy_move_second_part = false
				state = InPile
		InPile:
			pass

func _determine_global_mouse_pos() -> Vector2:
	# We're using this helper function, to allow our mouse-position relevant code to work during unit testing
	var mouse_position
	if cfc_config.NMAP.board.UT: mouse_position = cfc_config.NMAP.board.UT_mouse_position
	else: mouse_position = get_global_mouse_position()
	return mouse_position

func _determine_board_position_from_mouse() -> Vector2:
	#The following if statements prevents the dragged card from being dragged outside the viewport boundaries
	var targetpos: Vector2 = _determine_global_mouse_pos() + Vector2(10,10)
	if targetpos.x + $Control.rect_size.x * 0.4 >= get_viewport().size.x:
		targetpos.x = get_viewport().size.x - $Control.rect_size.x * scale.x
	if targetpos.x < 0:
		targetpos.x = 0
	if targetpos.y + $Control.rect_size.y * 0.4 >= get_viewport().size.y:
		targetpos.y = get_viewport().size.y - $Control.rect_size.y * scale.y
	if targetpos.y < 0:
		targetpos.y = 0
	return targetpos

func pushAside(targetpos: Vector2) -> void:
	# Instructs the card to move aside for another card enterring focus
	# We have it as its own function as it's called by other cards
	interruptTweening()
	target_position = targetpos
	state = PushedAside

func _recalculatePosition() ->Vector2:
	# This function recalculates the position of the current card object
	# based on how many cards we have already in hand and its index among them
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	# The number of cards currently in hand
	var hand_size: int = get_parent().get_card_count()
	# The maximum of horizontal pixels we want the cards to take
	# We simply use the size of the parent control container we've defined in the node settings
	var max_hand_size_width: float = get_parent().get_node('Control').rect_size.x
	# The maximum distance between cards
	# We base it on the card width to allow it to work with any card-size.
	var card_gap_max: float = $Control.rect_size.x * 1.1
	# The minimum distance between cards (less than card width means they start overlapping)
	var card_gap_min: float = $Control.rect_size.x/2
	# The current distance between cards. It is inversely proportional to the amount of cards in hand
	var cards_gap: float = max(min((max_hand_size_width - $Control.rect_size.x/2) / hand_size, card_gap_max), card_gap_min)
	# The current width of all cards in hand together
	var hand_width: float = (cards_gap * (hand_size-1)) + $Control.rect_size.x
	# The following just create the vector position to place this specific card in the playspace.
	card_position_x = max_hand_size_width/2 - hand_width/2 + cards_gap * get_my_card_index()
	# Since our control container has the same size as the cards, we start from 0,
	# and just offset the card if we want it higher or lower.
	card_position_y = 0 + bottom_margin
	return Vector2(card_position_x,card_position_y)
#
func reorganizeSelf() ->void:
	# We make the card find its expected position in the hand
	focus_completed = false # We clear the card as being in focus if it's reorganized
	match state:
		InHand, FocusedInHand, PushedAside:
			# We set the start position to their current position
			# this prevents the card object to teleport back to where it was if the animations change too fast
			# when the next animation happens
			target_position = _recalculatePosition()
			state = Reorganizing
	# This second match is  to prevent from changing the state when we're doing fancy movement
	# and we're still in the first part (which is waiting on an animation yield).
	# Instead, we just change the target position transparently, and when the second part of the animation begins
	# it will automatically pick up the right location.
	match state:
		MovingToContainer:
			target_position = _recalculatePosition()

func interruptTweening() ->void:
	# We use this function to stop existing card animations
	# then make sure they're properly cleaned-up to allow future animations to play.
	# This if-logic is there to avoid interrupting animations during fancy_movement,
	# as we want the first part to play always
	# Effectively we're saying if fancy movement is turned on, and you're still doing the first part, don't interrupt
	# If you've finished the first part and are not still in the move to another container movement, then you can interrupt.
	if not cfc_config.fancy_movement or (cfc_config.fancy_movement and (fancy_move_second_part or state != MovingToContainer)):
		$Tween.remove_all()
		state = InHand

func _on_Card_mouse_entered():
	# This triggers the focus-in effect on the card
	#print(state,":enter:",get_my_card_index()) # Debug
	print('enter')
	match state:
		InHand, Reorganizing,PushedAside:
			if not cfc_config.card_drag_ongoing:
				#print("focusing:",get_my_card_index()) # debug
				interruptTweening()
				state = FocusedInHand
		OnPlayBoard:
			#interruptTweening()
			state = FocusedOnBoard

func _on_Card_mouse_exited():
	# This triggers the focus-out effect on the card
	#print(state,"exit:",get_my_card_index()) # debug
	z_index = 0
	z_as_relative = true
	match state:
		FocusedInHand:
			print('exit')
			#focus_completed = false
			if get_parent() in cfc_config.hands:  # To avoid errors during fast player actions
				# Using Node2D instead of Control introduces an issue in that sometimes during very fast mouse movement
				# The detection of mouse enterring a new card comes earlier than the detection of the mouse exiting the previous one
				# This causes complications.
				# The code below will reset card organization only another card hasn't gotten focus in the meantime
				var another_focus := false
				for c in get_parent().get_all_cards():
					# Check if any other card has focus by now.
					if c != self and c.state == 1: another_focus = true
				if not another_focus:
					#print("resetting via:",get_my_card_index()) # debug
					for c in get_parent().get_all_cards():
						# We need to make sure afterwards all card will return to their expected positions
						# Therefore we simply stop all tweens and reorganize then whole hand
						c.interruptTweening()
						c.reorganizeSelf()
		FocusedOnBoard:
			focus_completed = false
			state = OnPlayBoard

func _on_Card_gui_input(_viewport,event,_idx):
	# A signal for whenever the player clicks on a card
	if event is InputEventMouseButton:
		match state:
			FocusedInHand, FocusedOnBoard:
				# If the player presses the left click, it might be because they want to drag the card
				if event.is_pressed() and event.get_button_index() == 1:
					# But first we check if the player does a long-press.
					# We don't want to start dragging the card immediately.
					dragging_attempted = true
					yield(get_tree().create_timer(0.1), "timeout")
					# If this variable is still set to true, it means the mouse-button is still pressed
					# We also check if another card is already selected for dragging,
					# to prevent from picking 2 cards at the same time.
					if dragging_attempted and not cfc_config.card_drag_ongoing:
						dragging_attempted = false
						# While the mouse is kept pressed, we tell the engine that a card is being dragged
						state = Dragged
						cfc_config.card_drag_ongoing = self
						if get_parent() in cfc_config.hands:
							# While we're dragging the card from hand, we want the other cards to move to their expected position in hand
							for c in get_parent().get_all_cards():
								if c != self:
									c.interruptTweening()
									c.reorganizeSelf()
				elif not event.is_pressed() and event.get_button_index() == 1:
					dragging_attempted = false

func _input(event):
	# We use _input because we want to also catch the signals when the player is dragging a card
	# because in that situation, the mouse will not be strictly on the card
	if event is InputEventMouseButton:
		if not event.is_pressed() and event.get_button_index() == 1:
			cfc_config.card_drag_ongoing = null
			match state:
				Dragged:
					focus_completed = false
					emit_signal("card_dropped",self)

func determine_idle_state() -> void:
	# Some logic is generic and doesn't always know the state the card should be afterwards
	# We use this function to determine the state it should have, based on the card's container grouping.
	if get_parent() in cfc_config.hands:
		state = InHand
	elif get_parent() in cfc_config.piles:
		state = InPile
	else:
		state = OnPlayBoard

func tween_interpolate_visibility(visibility: float, time: float) -> void:
	# Takes care to make a card change visibility nicely
	if modulate[3] != visibility: # We only want to do something if we're actually doing something
		$Tween.interpolate_property(self,'modulate',
		modulate, Color(1, 1, 1, visibility), time,
		Tween.TRANS_SINE, Tween.EASE_IN)

func reHost(targetHost):
	# We need to store the parent, because we won't be able to know it later
	var parentHost = get_parent()
	if targetHost != parentHost:
		# When changing parent, it resets the position of the child it seems
		# So we store it to know where the card used to be, before moving it
		var previous_pos = global_position
		var global_pos = global_position
		# We need to remove the current parent node before adding a different one
		parentHost.remove_child(self)
		targetHost.add_child(self)
		global_position = previous_pos # Ensure card stays where it was before it changed parents
		if targetHost in cfc_config.hands:
			visible = true
			tween_interpolate_visibility(1,0.5)
			# We need to adjust he end position based on the local rect inside the hand control node
			# So we transform global coordinates to hand rect coordinates.
			previous_pos = targetHost.to_local(global_pos)
			target_position = _recalculatePosition()
			state = MovingToContainer
			# We reorganize the left cards in hand.
			for c in targetHost.get_all_cards():
				if c != self:
					c.interruptTweening()
					c.reorganizeSelf()
		# 'HostedCards' here is the dummy child node inside Containers where we store the card objects
		elif targetHost in cfc_config.piles:
			state = InPile
			$Tween.remove_all() # Added because sometimes it ended up stuck and a card remained visible on top of deck
			# We need to adjust he end position based on the local rect inside the container control node
			# So we transform global coordinates to container rect coordinates.
			previous_pos = targetHost.to_local(global_pos)
			target_position = Vector2(0,0)
			state = MovingToContainer
			# If we have fancy movement, we need to wait for 2 tweens to finish before we vanish the card.
			if cfc_config.fancy_movement:
				yield($Tween, "tween_all_completed")
			tween_interpolate_visibility(0,0.3)
			yield($Tween, "tween_all_completed")
			visible = false
		# The state for the card being on the board
		else:
			interruptTweening()
			target_position = _determine_board_position_from_mouse()
			state = DroppingToBoard
		if parentHost in cfc_config.hands:
			# We also want to rearrange the hand when we take cards out of it
			for c in parentHost.get_all_cards():
				# But this time we don't want to rearrange ourselves, as we're in a different container by now
				if c != self:
					c.interruptTweening()
					c.reorganizeSelf()
	else:
		# Here we check what to do if the player just moved the card back to the same container
		if parentHost == cfc_config.NMAP.hand:
			state = InHand
			reorganizeSelf()
		if parentHost == cfc_config.NMAP.board:
			state = DroppingToBoard

func get_my_card_index() -> int:
	return get_parent().get_card_index(self)

