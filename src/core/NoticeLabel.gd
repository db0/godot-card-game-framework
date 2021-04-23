class_name NoticeLabel
extends Label

const FontColor := {
	"GREEN": Color(0,1,0),
	"RED": Color(1,0,0),
	"BLUE": Color(0,0,1),
	"WHITE": Color(1,1,1),
	"GREY": Color(0.5,0.5,0.5),
	"GLOW_RED": Color(3,1,1),
	"GLOW_GREEN": Color(1,3,1),
	"GLOW_BLUE": Color(1,1,3),
	"GLOW_WHITE": Color(3,3,3),
}

var hide_delay := 2.0
onready var _tween = $Tween

# Shows a fading text to the user notifying them of recent action results.
func set_notice(notice: String, colour := FontColor.GREEN, delay = hide_delay) -> void:
	text = notice
	modulate.a = 1
	set("custom_colors/font_color",colour)
	# warning-ignore:return_value_discarded
	_tween.remove_all()
	# warning-ignore:return_value_discarded
	_tween.interpolate_property(self,'modulate:a',
			1, 0, delay, Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	_tween.start()

