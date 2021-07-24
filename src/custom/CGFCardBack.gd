extends CardBackGlow

var font_scaled : float = 1

func _ready() -> void:
	viewed_node = $Viewed
	
# Since we have a label on top of our image, we use this to scale the label
# as well
# We don't care about the viewed icon, since it will never be visible
# in the viewport focus.
func scale_to(scale_multiplier: float) -> void:	
	if font_scaled != scale_multiplier:
		var label : Label = $Label
		label.rect_min_size *= scale_multiplier
		# We need to adjust the Viewed Container
		# a bit more to make the text land in the middle
#		$"VBoxContainer/CenterContainer".rect_min_size *= scale_multiplier * 1.5
		var label_font : Font = label.get("custom_fonts/font").duplicate()
		label_font.size *= scale_multiplier
		label.set("custom_fonts/font", label_font)
		font_scaled = scale_multiplier
	
