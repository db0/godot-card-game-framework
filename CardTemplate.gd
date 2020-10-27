extends Panel
class_name Card

# warning-ignore:unused_class_variable
export var scripts := [{'name':'','args':['',0]}]
enum{ # Finiste state engine for all posible states a card might be in
	InHand
	InPlay
	FocusedInHand
	MovingToContainer
	Reorganizing
}
var state := InHand
var start_position: Vector2
var target_position: Vector2
var current_interpolation_time := 0
var tweening_ongoing := false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func card_action() -> void:
	pass

func _process(delta):
	match state:
		InHand:
			pass
		InPlay:
			pass
		FocusedInHand:
			pass
		MovingToContainer:
			if tweening_ongoing == false:
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.75,
					Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				$Tween.start()
				tweening_ongoing = true
		Reorganizing:
			if tweening_ongoing == false:
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 0.5,
					Tween.TRANS_CUBIC, Tween.EASE_OUT)
				$Tween.start()
				tweening_ongoing = true

func moveToPosition(startpos: Vector2, targetpos: Vector2) -> void:
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
		var hand_size: float = container.get_child_count() 
		# The maximum of horizontal pixels we want the cards to take
		var max_hand_size_width: float = get_viewport().size.x - rect_size.x * 2
		# The maximum distance between cards
		var card_gap_max: float = rect_size.x * 1.1 
		# The minimum distance between cards (less than card width means they start overlapping)
		var card_gap_min: float = rect_size.x/2 
		# The current distance between cards. It is inversely proportional to the amount of cards in hand
		var cards_gap: float = max(min((max_hand_size_width - rect_size.x/2) / hand_size, card_gap_max), card_gap_min)
		# The current width of all cards in hand
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
	
#func send_to_destination() -> void: # Sends this card to the container it's supposed to belong after it's successfully used
#	if get_parent().name == "HandArray": # We only want to move cards like this when they're in hand.
#		$Hand.discard(self) 
#
#func _on_Card_gui_input(event) -> void:
#	if event.is_action_pressed("ui_select"):
#		if self.get_parent().name == 'HandArray':
#			# The global var has to go before the signal to allow cards which function instantly to be discarded
#			# This signal is intercepted by the Map scene which actives then the card effects.
#			card_action()
#	elif event.is_action_pressed("ui_discard") and self.get_parent().name == 'HandArray':
#		$Hand.discard(self)


func interruptTweening() ->void:
	$Tween.stop_all()
	state = InHand
	start_position = rect_position
	tweening_ongoing = false
	
func _on_Tween_tween_all_completed():
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
	tweening_ongoing = false
	#print(state)
