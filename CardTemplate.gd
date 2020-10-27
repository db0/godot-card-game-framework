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
					start_position, target_position, 1,
					Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				$Tween.start()
				tweening_ongoing = true
		Reorganizing:
			if tweening_ongoing == false:
				$Tween.interpolate_property($".",'rect_position',
					start_position, target_position, 1,
					Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				$Tween.start()
				tweening_ongoing = true

func moveToPosition(startpos: Vector2, targetpos: Vector2) -> void:
	start_position = startpos
	target_position = targetpos
	state = MovingToContainer

func recalculatePosition() ->Vector2:
	var container = get_parent()
	var card_position_x: float = 0
	var card_position_y: float = 0
	if container.name == 'Hand':
		var hand_size: float = container.get_child_count()
		var maxX = get_viewport().size.x - rect_size.x * 2
		var card_gap_max: float = rect_size.x * 1.1
		var card_gap_min: float = rect_size.x/2
		var cards_gap: float = max(min((maxX - rect_size.x/2) / hand_size, card_gap_max), card_gap_min)
		var hand_width: float = (cards_gap * (hand_size-1)) + rect_size.x
		card_position_x = get_viewport().size.x/2 - hand_width/2 + cards_gap * get_index()
		card_position_y = get_viewport().size.y / 2
	return Vector2(card_position_x,card_position_y)
#
func reorganizeSelf() ->void:
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
