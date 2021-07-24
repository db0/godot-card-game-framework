# This script should be attached to a card back which has been
# setup to modulate its colour intensity
# so that it appears to glow and change glow intensity
class_name CardBackGlow
extends CardBack

# Used for looping between brighness scales for the Cardback glow
# The multipliers have to be small, as even small changes increase
# brightness a lot
var _pulse_values := [Color(1.05,1.05,1.05),Color(0.9,0.9,0.9)]
# A link to the tween which changes the glow intensity
# For this class, a Tween node called Pulse must exist at the root of the scene.
onready var _tween = $Pulse


func _ready() -> void:
	# warning-ignore:return_value_discarded
	_tween.connect("tween_all_completed", self, "_on_Pulse_completed")


# Reverses the card back pulse and starts it again
func _on_Pulse_completed() -> void:
	# We only pulse the card if it's face-down and on the board
	if not card_owner.is_faceup: #and get_parent() == cfc.NMAP.board:
		_pulse_values.invert()
		start_card_back_animation()
	else:
		stop_card_back_animation()


# Initiates the looping card back pulse
# The pulse increases and decreases the brightness of the glow
func start_card_back_animation():
	_tween.interpolate_property(self,'modulate',
			_pulse_values[0], _pulse_values[1], 2,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.start()


# Disables the looping card back pulse
func stop_card_back_animation():
	_tween.remove_all()
	modulate = Color(1,1,1)
