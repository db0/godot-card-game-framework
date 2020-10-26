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

func _physics_process(delta):
	match state:
		InHand:
			pass
		InPlay:
			pass
		FocusedInHand:
			pass
		MovingToContainer:
			if tweening_ongoing == false:
				if current_interpolation_time <= 1:
					$Tween.interpolate_property($".",'rect_position',
						start_position, target_position, 1,
						Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
					$Tween.start()
				tweening_ongoing = true
			else:
				state = InHand
				current_interpolation_time = 0
		Reorganizing:
			pass

func moveToContainer(startpos: Vector2, targetpos: Vector2):
	start_position = startpos
	target_position = targetpos
	state = MovingToContainer
	
#
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
