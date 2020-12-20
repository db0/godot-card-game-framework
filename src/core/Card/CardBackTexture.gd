# This script should be attached to a card back which is using a simple
# texture as a card back and doesn't have any special animations
class_name CardBackTexture
extends CardBack


func _ready() -> void:
	# warning-ignore:return_value_discarded
	viewed_node = $VBoxContainer/CenterContainer/Viewed
	
