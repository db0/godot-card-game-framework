# This script should be attached to a card back which is using a pbr
# texture as a card back and  have any special animations
# The card back has three layers
# bottom_layer is card bottom texture
# middle_layer is special animations
# top_layer is card skeleton texture
class_name CardBackModel
extends CardBack

export(int) var bottom_type = 1
export(int) var middle_type = 1
export(int) var top_type = 1

func _ready() -> void:
	# warning-ignore:return_value_discarded
	viewed_node = $VBoxContainer/CenterContainer/Viewed
	var card_back_3d = load(CFConst.PATH_CARD_BACK_MODEL+ "CardBack3d.tscn")
	var card_back_insance = card_back_3d.instance()
	card_back_insance.bottom_type = bottom_type
	card_back_insance.middle_type = middle_type
	card_back_insance.top_type = top_type
	$ViewportContainer/Viewport.add_child(card_back_insance)
