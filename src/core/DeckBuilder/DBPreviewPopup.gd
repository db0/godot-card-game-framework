class_name DBPreviewPopup
extends Popup

var preview_card: Card
onready var focus_info := $FocusInfo

func _process(_delta: float) -> void:
	if visible:
		rect_position = get_preview_placement()
		# This ensures the FocusInfoPanel is always on the bottom of the card
		if CFConst.VIEWPORT_FOCUS_ZOOM_TYPE == "scale":
			focus_info.rect_size.x = CFConst.CARD_SIZE.x * preview_card.scale.x
			focus_info.rect_position.y = CFConst.CARD_SIZE.y * preview_card.scale.y
		else:
			focus_info.rect_size.x = preview_card.card_size.x * CFConst.PREVIEW_SCALE
			focus_info.rect_position.y = preview_card.card_size.y * CFConst.PREVIEW_SCALE

func get_preview_placement() -> Vector2:
	# warning-ignore:unassigned_variable
	var ret : Vector2
	var focus_panel_offset = 0
	if focus_info.visible:
		focus_panel_offset = focus_info.rect_size.y
	var card_size := preview_card.card_size
	card_size = CFConst.CARD_SIZE * CFConst.PREVIEW_SCALE
	if get_global_mouse_position().x\
			+ card_size.x\
			> get_viewport().size.x:
		ret.x = get_viewport().size.x\
				- card_size.x\
				* preview_card.scale.x
	else:
		ret.x = get_global_mouse_position().x + 10
	if get_global_mouse_position().y\
			+ card_size.y\
			+ focus_panel_offset\
			> get_viewport().size.y:
		ret.y = get_viewport().size.y\
				- card_size.y\
				* preview_card.scale.y\
				- focus_panel_offset
	else:
		ret.y = get_global_mouse_position().y
	return(ret)

func show_preview_card(card_name) -> void:
	preview_card = cfc.instance_card(card_name)
	add_child(preview_card)
	# It's necessary we do this here because if we only we it during
	# the process, the card will appear to teleport
	if CFConst.VIEWPORT_FOCUS_ZOOM_TYPE == "resize":
		preview_card.resize_recursively(preview_card._control, CFConst.PREVIEW_SCALE)
		preview_card.card_front.scale_to(CFConst.PREVIEW_SCALE)
	rect_position = get_preview_placement()
	cfc.ov_utils.populate_info_panels(preview_card,focus_info)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true


func hide_preview_card() -> void:
	if is_instance_valid(preview_card):
		preview_card.queue_free()
	visible = false
