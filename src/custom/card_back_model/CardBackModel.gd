extends Sprite3D

export(int) var bottom_type
export(int) var middle_type
export(int) var top_type

func _ready():
	init_card_back()


func init_card_back():
	var bottom_layer = load(CFConst.PATH_CARD_BACK_BOTTOM
			+ str(bottom_type) + "/bottom.tres")
	var middle_layer = load(CFConst.PATH_CARD_BACK_MIDDLE
			+ str(middle_type) + "/middle.tres")
	var top_layer = load(CFConst.PATH_CARD_BACK_TOP
			+ str(top_type) + "/top.tres")
	material_override = bottom_layer
	bottom_layer.render_priority = 1
	bottom_layer.next_pass = middle_layer
	middle_layer.render_priority = 2
	middle_layer.next_pass = top_layer
	top_layer.render_priority = 3
