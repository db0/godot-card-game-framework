extends Panel
class_name Card

# warning-ignore:unused_class_variable
export var scripts := [{'name':'','args':['',0]}]
enum{ # Finite state engine for all posible states a card might be in
	  # This simply is a way to refer to the values with a human-readable name.
	InHand
	InPlay
	FocusedInHand
	MovingToContainer
	Reorganizing
}
var state := InHand # Starting state for each card
var start_position: Vector2 # Used for animating the card
var target_position: Vector2 # Used for animating the card

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func card_action() -> void:
	pass

func _process(_delta):
	# A basic finite state engine
	match state:
		InHand:
			pass
		InPlay:
			pass
		FocusedInHand:
			# Used when moving card between places (i.e. deck to hand, hand to table etc)
			if not $Tween.is_active():
				var expected_position: Vector2 = recalculatePosition()
				if rect_position.is_equal_approx(expected_position):
					$Tween.interpolate_property($".",'rect_position',
						expected_position, expected_position - Vector2(0,rect_size.y * 0.5), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
					$Tween.interpolate_property($".",'rect_scale',
						rect_scale, Vector2(1.5,1.5), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
					$Tween.start()
		MovingToContainer:
			# Used when moving card between places (i.e. deck to hand, hand to table etc)
			if not $Tween.is_active():
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.75,
					Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				$Tween.start()
		Reorganizing:
			# Used when reorganizing the cards in the hand
			if not $Tween.is_active():
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.5,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				if not rect_scale.is_equal_approx(Vector2(1,1)):
					$Tween.interpolate_property($".",'rect_scale',
						rect_scale, Vector2(1,1), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Tween.start()

			else: state = InHand

func moveToPosition(startpos: Vector2, targetpos: Vector2) -> void:
	# Called by external objects to instruct the card to move to another position on the table.
	start_position = startpos
	target_position = targetpos
	state = MovingToContainer

func recalculatePosition() ->Vector2:
	# This function recalculates the position of the current card object
	# based on how many cards we have already in hand and its index among them
	var container = get_parent()
	var card_position_x: float = 0
	var card_position_y: float = 0
	if container.name == 'Hand':
		# The number of cards currently in hand
		var hand_size: int = container.get_child_count() 
		# The maximum of horizontal pixels we want the cards to take
		# We base it on the available space in the Godot window to allow it to work with any resolution or resize.
		var max_hand_size_width: float = get_viewport().size.x - rect_size.x * 2
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
		card_position_y = get_viewport().size.y - rect_size.y
	return Vector2(card_position_x,card_position_y)
#
func reorganizeSelf() ->void:
	# We make the card find its expected position in the hand
	if state == InHand:
		target_position = recalculatePosition()
		state = Reorganizing


func interruptTweening() ->void:
	# We use this function to stop existing card animations 
	# then make sure they're properly cleaned-up to allow future animations to play.
	$Tween.remove_all()
	state = InHand
	# We set the start position to their current position
	# this prevents the card object to teleport back to where it was before the interrupted animation
	# when the next animation happens
	start_position = rect_position

func _on_Tween_tween_all_completed():
	# Sync tweens are asynchronous, we cannot change the finite state during _process
	# Instead we make sure the finite state goes to the next part when the animations are done.
	match state:
		InHand:
			pass
		InPlay:
			pass
		FocusedInHand:
			pass
		MovingToContainer:
			state = InHand
			start_position = target_position
		Reorganizing:
			state = InHand
			start_position = target_position

func _on_Card_mouse_entered():
	match state:
		InHand, Reorganizing:
			state = FocusedInHand

func _on_Card_mouse_exited():
	match state:
		FocusedInHand:
			start_position = rect_position
			state = Reorganizing
