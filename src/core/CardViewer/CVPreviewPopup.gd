# The popup with an instance of a card instide. 
# Typically in larger version for easy viewing.
class_name CVPreviewPopup
extends Popup

# The card currently being shown in a popup.
var preview_card: Card
# The popup panel which contains the card.
onready var focus_info := $FocusInfo

func _ready() -> void:
# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')


func _process(_delta: float) -> void:
	if visible and is_instance_valid(preview_card):
		rect_position = get_preview_placement()
		# This ensures the FocusInfoPanel is always on the bottom of the card
#		for c in focus_info.get_children():
#			# We use this to adjust the info panel labels depending on how the 
#			# PREVIEW_SCALE is
#			c.get_node("Details").rect_min_size.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale
#			c.get_node("Details").rect_size.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale
#			c.rect_min_size.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale
#			c.rect_size.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale
		focus_info.rect_min_size.x = 0.0
		focus_info.rect_size.x = 0.0
		focus_info.rect_position.y = 0
		focus_info.rect_position.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale


# Figures out where to place the card preview in respect to the player's mouse.
func get_preview_placement() -> Vector2:
	# warning-ignore:unassigned_variable
	var ret : Vector2
	var focus_panel_offset = 0
	var card_size : Vector2 = preview_card.canonical_size * preview_card.preview_scale * cfc.curr_scale
	# If the card width is to small, we will place the info panels instead to the left of the card preview
	if focus_info.visible:
		focus_panel_offset = focus_info.rect_size.y
	# We want the card to be on the right of the mouse always
	# Unless that would make it hide outside the viewport.
	# In which case we place it on the left of the mouse instead
#	if get_global_mouse_position().x\
#			+ card_size.x\
#			+ 20\
#			> get_viewport().size.x:
#		ret.x = get_global_mouse_position().x - card_size.x - 20
#	else:
#		ret.x = get_global_mouse_position().x + 20
#	if is_instance_valid(preview_card) and get_global_mouse_position().y\
#			+ card_size.y\
#			+ focus_panel_offset\
#			> get_viewport().size.y:
#		ret.y = get_viewport().size.y\
#				- card_size.y\
#				* preview_card.scale.y\
#				- focus_panel_offset
#	else:
#		ret.y = get_global_mouse_position().y
	if focus_info.visible:
		focus_panel_offset = focus_info.rect_size.x
	if get_global_mouse_position().x\
			+ card_size.x\
			+ 20\
			+ focus_panel_offset\
			> get_viewport().size.x:
		ret.x = get_global_mouse_position().x - card_size.x - 20 - focus_panel_offset
	else:
		ret.x = get_global_mouse_position().x + 20
	var card_offscreen_y = get_global_mouse_position().y\
			+ card_size.y\
			* preview_card.scale.y
	var focus_offscreen_y = get_global_mouse_position().y + focus_info.rect_size.y
	if card_offscreen_y > focus_offscreen_y\
			and is_instance_valid(preview_card)\
			and card_offscreen_y > get_viewport().size.y:
		ret.y = get_viewport().size.y\
				- card_size.y\
				* preview_card.scale.y
	elif card_offscreen_y < focus_offscreen_y\
			and focus_offscreen_y > get_viewport().size.y:
		ret.y = get_viewport().size.y\
				- focus_info.rect_size.y
	else:
		ret.y = get_global_mouse_position().y
#	print_debug(ret)
	return(ret)

# Instances a card object. Populates it with the card details
# Then displays it in the popup.
func show_preview_card(card_name) -> void:
	if not is_instance_valid(preview_card):
		preview_card = cfc.instance_card(card_name)
		add_child(preview_card)
		# It's necessary we do this here because if we only we it during
		# the process, the card will appear to teleport
		if CFConst.VIEWPORT_FOCUS_ZOOM_TYPE == "resize":
			preview_card.resize_recursively(preview_card._control, preview_card.preview_scale * cfc.curr_scale)
			preview_card.card_front.scale_to(preview_card.preview_scale * cfc.curr_scale)
		rect_position = get_preview_placement()
		cfc.ov_utils.populate_info_panels(preview_card,focus_info)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 1
	visible = true


# Deinstances the currently shown card.
func hide_preview_card() -> void:
	modulate.a = 0

# We want to recreate the popup after the viewport size has changed
# As otherwise its elements may end up messed up
func _on_viewport_resized() -> void:
	if is_instance_valid(preview_card):
		preview_card.queue_free()
