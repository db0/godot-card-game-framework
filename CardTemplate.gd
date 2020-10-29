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
# The amount by which to reduce the max hand size width, comparative to the total viewport width
# The default of 2*card width means that if the hand if full of cards, there will be empty space on both sides
# equal to one card's width
onready var hand_width_margin := rect_size.x * 2
# The margin from the bottom of the viewport on which to draw the cards.
# Less than 1 card heigh and the card will appear hidden under the monitor.
# More and it will float higher than the bottom of then viewport
onready var bottom_margin := rect_size.y/2
### END Behaviour Constants ###

# warning-ignore:unused_class_variable
# We export this variable to the editor to allow us to add scripts to each card object directly instead of only via code.
export var scripts := [{'name':'','args':['',0]}]
enum{ # Finite state engine for all posible states a card might be in
	  # This simply is a way to refer to the values with a human-readable name.
	InHand
	InPlay
	FocusedInHand
	MovingToContainer
	Reorganizing
	PushedAside
}
var state := InHand # Starting state for each card
var start_position: Vector2 # Used for animating the card
var target_position: Vector2 # Used for animating the card
var focus_completed: bool = false # Used to avoid the focus animation repeating once it's completed.
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
				if not focus_completed:
					for neighbour_index_diff in [-2,-1,1,2]:
						var hand_size: int = get_parent().get_child_count()
						var neighbour_index: int = get_index() + neighbour_index_diff
						if neighbour_index >= 0 and neighbour_index <= hand_size - 1:
							var neighbour_card: Card = get_parent().get_child(neighbour_index)
							neighbour_card.interruptTweening()
							neighbour_card.start_position = neighbour_card.rect_position
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
			# Used when moving card between places (i.e. deck to hand, hand to table etc)
			if not $Tween.is_active():
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.75,
					Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				$Tween.start()
				state = InHand
		Reorganizing:
			# Used when reorganizing the cards in the hand
			if not $Tween.is_active():
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.4,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				if not rect_scale.is_equal_approx(Vector2(1,1)):
					$Tween.interpolate_property($".",'rect_scale',
						rect_scale, Vector2(1,1), 0.4,
						Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.start()
				state = InHand
			#else: state = InHand
		PushedAside:
			# Used when card is being pushed aside due to focusing of a neighbour.
			if not $Tween.is_active() and not rect_position.is_equal_approx(target_position):
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.3,
					Tween.TRANS_QUART, Tween.EASE_IN)
				if not rect_scale.is_equal_approx(Vector2(1,1)):
					$Tween.interpolate_property($".",'rect_scale',
						rect_scale, Vector2(1,1), 0.3,
						Tween.TRANS_QUART, Tween.EASE_IN)
				$Tween.start()
				# We don't change state yet, only when the focus is removed from the neighbour

func moveToPosition(startpos: Vector2, targetpos: Vector2) -> void:
	# Called by external objects to instruct the card to move to another position on the table.
	start_position = startpos
	target_position = targetpos
	state = MovingToContainer

func pushAside(targetpos: Vector2) -> void:
	# Called by external objects to instruct the card to move to another position on the table.
	target_position = targetpos
	state = PushedAside

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

func interruptTweening() ->void:
	# We use this function to stop existing card animations
	# then make sure they're properly cleaned-up to allow future animations to play.
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
			for c in get_parent().get_children():
				# We need to make sure afterwards all card will return to their expected positions
				# Therefore we simply stop all tweens and reorganize then whole hand
				c.interruptTweening()
				c.reorganizeSelf()

