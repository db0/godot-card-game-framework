extends Control
class_name Card
# This class is meant to be used as the basis for your card scripting
# Simply make your card scripts extend this class and you'll have all the provided scripts available
# If your card node type is not control, make sure you change the extends type above

### BEGIN Behaviour Constants ###
### Change the below to change how all cards behave to match your game.
# The amount of distance neighboring cards are pushed during card focus
# It's based on the card width. Bigger percentage means larger push.
const neighbour_push := 0.75
# The scale of the card while on the play area
const play_area_scale := Vector2(0.8,0.8)
# The amount by which to reduce the max hand size width, comparative to the total viewport width
# The default of 2*card width means that if the hand if full of cards, there will be empty space on both sides
# equal to one card's width
onready var hand_width_margin := rect_size.x * 2
# The margin from the bottom of the viewport on which to draw the cards.
# Less than 1 card heigh and the card will appear hidden under the display area.
# More and it will float higher than the bottom of the viewport
onready var bottom_margin := rect_size.y/2
# Switch this off to disable fancy movement of cards during draw/discard
var fancy_movement_setting := true
# The below vars predefine the position in your node structure to reach the nodes relevant to the cards
# Adapt this according to your node structure. Do not prepent /root in front, as this is assumed
var nodes_map := {
	'board': "Board",
	'hand': "Board/Hand",
	'deck': "Board/Deck/HostedCards",
	'discard': "Board/DiscardPile/HostedCards"
	}
### END Behaviour Constants ###

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
	DroppingIntoContainer 	#8
	InContainer				#9
}
var state := InContainer # Starting state for each card
var start_position: Vector2 # Used for animating the card
var target_position: Vector2 # Used for animating the card
var focus_completed: bool = false # Used to avoid the focus animation repeating once it's completed.
var timer: float = 0
var fancy_move_second_part := false # We use this to know at which stage of fancy movement this is.
var fancy_movement := fancy_movement_setting # Gets value from initial const, but allows from programmatic change
var CP := {} # CP stands for CardParent. I'm using a short form here as we'll be retyping this a lot

# Called when the node enters the scene tree for the first time.
func _ready():
	# The below code allows us to quickly refer to nodes meant to host cards (i.e. parents) 
	# using an human-readable name
	for node in nodes_map.keys():
		CP[node]  = get_node('/root/' + nodes_map[node])

func card_action() -> void:
	pass

func _process(delta):
	# A basic finite state engine
	match state:
		InHand:
			pass
		FocusedInHand:
			# Used when card is focused on by the mouse hovering over it.
			if not $Tween.is_active() and not focus_completed:
				var expected_position: Vector2 = recalculatePosition()
				for neighbour_index_diff in [-2,-1,1,2]:
					var hand_size: int = get_parent().get_child_count()
					var neighbour_index: int = get_index() + neighbour_index_diff
					if neighbour_index >= 0 and neighbour_index <= hand_size - 1:
						var neighbour_card: Card = get_parent().get_child(neighbour_index)
						# Neighbouring cards are pushed to the side to allow the focused card to not be overlapped
						# The amount they're pushed is relevant to how close neighbours they are.
						# Closest neighbours (1 card away) are pushed more than further neighbours.
						neighbour_card.pushAside(neighbour_card.recalculatePosition() + Vector2(neighbour_card.rect_size.x/neighbour_index_diff * neighbour_push,0))
				# When zooming in, we also want to move the card higher, so that it's not under the screen's bottom edge.
				target_position = expected_position - Vector2(rect_size.x * 0.25,rect_size.y * 0.5 + bottom_margin)
				start_position = expected_position
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.3,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.interpolate_property($".",'rect_scale',
					rect_scale, Vector2(1.5,1.5), 0.3,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.start()
				focus_completed = true
				# We don't change state yet, only when the focus is removed from this card
		MovingToContainer:
			# Used when moving card between places (i.e. deck to hand, hand to discard etc)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if fancy_movement:
					# The below calculations figure out the intermediate position as a spot offset
					# towards the viewport center by an amount proportional to distance from the viewport center.
					# (My math is not the best so there's probably a more elegant formula)
					var direction_x: int = 1
					var direction_y: int = 1
					if target_position.x < get_viewport().size.x/2: direction_x = -1
					if target_position.y < get_viewport().size.y/2: direction_y = -1
					var inter_x = target_position.x - direction_x * (abs(target_position.x - get_viewport().size.x/2)) / 100 * rect_size.x
					var inter_y = target_position.y - direction_y * (abs(target_position.y - get_viewport().size.y/2)) / 250 * rect_size.y
					intermediate_position = Vector2(inter_x,inter_y)
					$Tween.interpolate_property(self,'rect_global_position',
						start_position, intermediate_position, 0.5,
						Tween.TRANS_BACK, Tween.EASE_IN_OUT)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					fancy_move_second_part = true
				else:
					intermediate_position = start_position
				if state == MovingToContainer: # We need to check again, just in case it's been reorganized instead.
					$Tween.interpolate_property(self,'rect_global_position',
						intermediate_position, target_position, 0.35,
						Tween.TRANS_SINE, Tween.EASE_IN_OUT)
					$Tween.start()
					determine_idle_state()
				fancy_move_second_part = false
		Reorganizing:
			# Used when reorganizing the cards in the hand
			if not $Tween.is_active():
				$Tween.interpolate_property(self,'rect_position',
					start_position, target_position, 0.4,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				if not rect_scale.is_equal_approx(Vector2(1,1)):
					$Tween.interpolate_property(self,'rect_scale',
						rect_scale, Vector2(1,1), 0.4,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				tween_interpolate_visibility(1,0.4)
				$Tween.start()
				state = InHand
		PushedAside:
			# Used when card is being pushed aside due to the focusing of a neighbour.
			if not $Tween.is_active() and not rect_position.is_equal_approx(target_position):
				$Tween.interpolate_property(self,'rect_position',
					start_position, target_position, 0.3,
					Tween.TRANS_QUART, Tween.EASE_IN)
				if not rect_scale.is_equal_approx(Vector2(1,1)):
					$Tween.interpolate_property(self,'rect_scale',
						rect_scale, Vector2(1,1), 0.3,
						Tween.TRANS_QUART, Tween.EASE_IN)
				$Tween.start()
				# We don't change state yet, only when the focus is removed from the neighbour
		Dragged:
			# The timer prevents the card from being moved immediately on mouse click.
			# It instead waits a natural time to confirm this is long-mouse press before it starts shrinking the card.
			timer += delta
			if timer >= 0.15:
				if not $Tween.is_active():
					$Tween.interpolate_property(self,'rect_scale',
						rect_scale, Vector2(0.4,0.4), 0.2,
						Tween.TRANS_SINE, Tween.EASE_IN)
					$Tween.start()
				rect_position = determine_board_position_from_mouse()
		OnPlayBoard:
			pass
		DroppingToBoard:
			# Used when dropping the cards to the table
			# When dragging the card, the card is slightly behind the mouse cursor
			# so we tween it to the right location
			if not $Tween.is_active():
				$Tween.interpolate_property(self,'rect_position',
					rect_position, determine_board_position_from_mouse(), 0.25,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				# We want cards on the board to be slightly smaller than in hand.
				if not rect_scale.is_equal_approx(play_area_scale):
					$Tween.interpolate_property(self,'rect_scale',
						rect_scale, play_area_scale, 0.5,
						Tween.TRANS_BOUNCE, Tween.EASE_OUT)
				$Tween.start()
				state = OnPlayBoard
		DroppingIntoContainer:
			# Used when dropping the cards into a container (Deck, Discard etc)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if fancy_movement:
					intermediate_position = get_parent().rect_position - Vector2(0,rect_size.y*1.1)
					$Tween.interpolate_property(self,'rect_position',
						rect_position, intermediate_position, 0.25,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
					yield($Tween, "tween_all_completed")
					if not rect_scale.is_equal_approx(play_area_scale):
						$Tween.interpolate_property(self,'rect_scale',
							rect_scale, Vector2(1,1), 0.5,
							Tween.TRANS_BOUNCE, Tween.EASE_OUT)
					$Tween.start()
					fancy_move_second_part = true
				else:
					intermediate_position = get_parent().rect_position
				$Tween.interpolate_property(self,'rect_global_position',
					intermediate_position, get_parent().rect_position, 0.35,
					Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				$Tween.start()
				determine_idle_state()
				fancy_move_second_part = false
				state = InContainer
		InContainer:
			pass

func determine_global_mouse_pos() -> Vector2:
	# We're using this helper function, to allow our mouse-position relevant code to work during unit testing
	var mouse_position
	if CP.board.UT: mouse_position = CP.board.UT_mouse_position
	else: mouse_position = get_global_mouse_position()
	return mouse_position

func determine_board_position_from_mouse() -> Vector2:
	#The following if statements prevents the dragged card from being dragged outside the viewport boundaries
	var targetpos: Vector2 = determine_global_mouse_pos() + Vector2(10,10)
	if targetpos.x + rect_size.x * 0.4 >= get_viewport().size.x:
		targetpos.x = get_viewport().size.x - rect_size.x * rect_scale.x
	if targetpos.x < 0:
		targetpos.x = 0
	if targetpos.y + rect_size.y * 0.4 >= get_viewport().size.y:
		targetpos.y = get_viewport().size.y - rect_size.y * rect_scale.y
	if targetpos.y < 0:
		targetpos.y = 0
	return targetpos

func moveToPosition(startpos: Vector2, targetpos: Vector2) -> void:
	# Instructs the card to move to another position on the table.
	start_position = startpos
	target_position = targetpos
	state = MovingToContainer

func pushAside(targetpos: Vector2) -> void:
	# Instructs the card to move aside for another card enterring focus
	interruptTweening()
	start_position = rect_position
	target_position = targetpos
	state = PushedAside

func recalculatePosition() ->Vector2:
	# This function recalculates the position of the current card object
	# based on how many cards we have already in hand and its index among them
	var card_position_x: float = 0
	var card_position_y: float = 0
	# The number of cards currently in hand
	var hand_size: int = get_parent().get_child_count()
	# The maximum of horizontal pixels we want the cards to take
	# We base it on the available space in the Godot window to allow it to work with any resolution or resize.
	var max_hand_size_width: float = get_viewport().size.x - hand_width_margin
	# The maximum distance between cards
	# We base it on the card width to allow it to work with any card-size.
	var card_gap_max: float = rect_size.x * 1.1
	# The minimum distance between cards (less than card width means they start overlapping)
	var card_gap_min: float = rect_size.x/2
	# The current distance between cards. It is inversely proportional to the amount of cards in hand
	var cards_gap: float = max(min((max_hand_size_width - rect_size.x/2) / hand_size, card_gap_max), card_gap_min)
	# The current width of all cards in hand together
	var hand_width: float = (cards_gap * (hand_size-1)) + rect_size.x
	# The following just create the vector position to place this specific card in the playspace.
	card_position_x = get_viewport().size.x/2 - hand_width/2 + cards_gap * get_index()
	card_position_y = get_viewport().size.y - bottom_margin
	return Vector2(card_position_x,card_position_y)
#
func reorganizeSelf() ->void:
	# We make the card find its expected position in the hand
	match state:
		InHand, FocusedInHand, PushedAside:
			# We set the start position to their current position
			# this prevents the card object to teleport back to where it was if the animations change too fast
			# when the next animation happens
			start_position = rect_position
			target_position = recalculatePosition()
			state = Reorganizing
	# This second match is  to prevent from changing the state when we're doing fancy movement
	# and we're still in the first part (which is waiting on an animation yield).
	# Instead, we just change the target position transparently, and when the second part of the animation begins
	# it will automatically pick up the right location.
	match state:
		MovingToContainer:
			start_position = rect_position
			target_position = recalculatePosition()

func interruptTweening() ->void:
	# We use this function to stop existing card animations
	# then make sure they're properly cleaned-up to allow future animations to play.
	# This if-logic is there to avoid interrupting animations during fancy_movement,
	# as we want the first part to play always
	# Effectively we're saying if fancy movement is turned on, and you're still doing the first part, don't interrupt
	# If you've finished the first part and are not still in the move to another container movement, then you can interrupt.
	if not fancy_movement or (fancy_movement and (fancy_move_second_part or state != MovingToContainer)):
		$Tween.remove_all()
		state = InHand

func _on_Card_mouse_entered():
	# This triggers the focus-in effect on the card
	match state:
		InHand, Reorganizing:
			interruptTweening()
			state = FocusedInHand

func _on_Card_mouse_exited():
	# This triggers the focus-out effect on the card
	match state:
		FocusedInHand:
			focus_completed = false
			if get_parent().name == 'Hand':  # To avoid errors during fast player actions
				for c in get_parent().get_children():
					# We need to make sure afterwards all card will return to their expected positions
					# Therefore we simply stop all tweens and reorganize then whole hand
					c.interruptTweening()
					c.reorganizeSelf()

func _on_Card_gui_input(event):
	# A signal for whenever the player clicks on a card
	if event is InputEventMouseButton:
		match state:
			FocusedInHand, Dragged:
				# If the player presses the left click, it might be because they want to drag the card
				if event.is_pressed() and event.get_button_index() == 1:
					# While the mouse is kept pressed, we tell the engine that a card is being dragged
					state = Dragged
					# While we're dragging the card, we want the other cards to move to their expected position in hand
					for c in get_parent().get_children():
						if c != self:
							c.interruptTweening()
							c.reorganizeSelf()

func _input(event):
	if event is InputEventMouseButton:
		match state:
			FocusedInHand, Dragged:
				if not event.is_pressed() and event.get_button_index() == 1:
					focus_completed = false
					# We check if the player released the card in the "virtual" hand area. If so, we leave it in hand
					if determine_global_mouse_pos().y + get_parent().hand_rect.y >= get_viewport().size.y:
					# Here we try to avoid a card losing focus when the player clicks once on it
					# However we cannot compare using is_equal_approx() because the rect_position.y will have changed
					# due to the focusing of the card
					# Instead we simply check if the position x has not changed from its focused position
					# if the x position has changed, it indicated the player has dragged the card.
						if not abs(rect_position.x - recalculatePosition().x + 37.5) < 0.01:
							state = InHand
							reorganizeSelf()
						# If the player has not moved the card, clicking once should do nothing
						# However this is not a perfect implementation. But it will do for now.
						else:
							state = FocusedInHand
					# If the card is not left in the hand rect, it's on the table
					# (More elif to follow for discard and deck.)
					else:
						reHost(get_parent().get_parent())  # we assume the playboard is the parent of the card
					timer = 0

func determine_idle_state() -> void:
	# Some logic is generic and doesn't always know the state the card should be afterwards
	# We use this function to determine the state it should have, based on the card's container node.
	match get_parent().name:
		'Board': state = OnPlayBoard
		'Hand': state = InHand
		'HostedCards': state = InContainer

func tween_interpolate_visibility(visibility: float, time: float) -> void:
	# Takes care to make a card change visibility nicely
	$Tween.interpolate_property(self,'modulate',
	modulate, Color(1, 1, 1, visibility), time,
	Tween.TRANS_SINE, Tween.EASE_IN)

func reHost(targetHost):
	# We need to store the parent, because we won't be able to know it later
	var parentHost = get_parent()
	if targetHost != parentHost:
		# When changing parent, it resets the position of the child it seems
		# So we store it to know where the card used to be, before moving it
		var previous_pos = rect_global_position
		# We need to remove the current parent node before adding a different one
		parentHost.remove_child(self)
		targetHost.add_child(self)
		rect_global_position = previous_pos # Ensure card stays where it was before it changed parents
		match targetHost.name:
			# The state for the card being on the board
			'Board':
				state = DroppingToBoard
			'Hand':
				visible = true
				fancy_movement = fancy_movement_setting
				tween_interpolate_visibility(1,0.5)
				# We reorganize the left cards in hand.
				moveToPosition(previous_pos,recalculatePosition())
				for c in targetHost.get_children():
					if c != self:
						c.interruptTweening()
						c.reorganizeSelf()
			# 'HostedCards' here is the dummy child node inside Containers where we store the card objects
			'HostedCards':
				state = InContainer
				$Tween.remove_all() # Added because sometimes it ended up stuck and a card remained visible on top of deck
				tween_interpolate_visibility(0,0.3)
				moveToPosition(previous_pos,targetHost.get_parent().rect_position)
				yield($Tween, "tween_all_completed")
				visible = false
		match parentHost.name:
			# We also want to rearrange the hand when we take cards out of it
			'Hand':
				for c in parentHost.get_children():
					# But this time we don't want to rearrange ourselves, as we're in a different container by now
					if c != self:
						c.interruptTweening()
						c.reorganizeSelf()
