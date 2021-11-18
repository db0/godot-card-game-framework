# This script should be attached to a card back which is using a simple
# texture as a card back and doesn't have any special animations
class_name CardBackTexture
extends CardBack

export(StreamTexture) var back_texture: StreamTexture

onready var card_texture := $CardTexture


func _ready() -> void:
	# warning-ignore:return_value_discarded
	viewed_node = $VBoxContainer/CenterContainer/Viewed
	_prepare_back_from_texture()

func _prepare_back_from_texture() -> void:
	if back_texture:
		card_texture.texture = CFUtils.convert_texture_to_image(
				back_texture, true)



func set_card_back(filename) -> void:
	var new_texture = CFUtils.convert_texture_to_image(filename)
	card_texture.texture = new_texture
	card_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
