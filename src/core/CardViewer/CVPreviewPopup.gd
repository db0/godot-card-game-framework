# The popup with an instance of a card instide. 
# Typically in larger version for easy viewing.
class_name CVPreviewPopup
extends Popup

signal placement_initialized
# The card currently being shown in a popup.
var preview_card: Card
var _tween_wait := 0
var _placement_initialized := false
var _visible = true
# The popup panel which contains the card.
onready var focus_info := $FocusInfo
onready var _tween := $Tween

func _ready() -> void:
# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, '_on_viewport_resized')
	connect("placement_initialized",self, "_on_placement_initialized")

func _process(_delta: float) -> void:
	if _placement_initialized and visible and is_instance_valid(preview_card):
		_set_placement()

func _set_placement() -> void:
	if _tween.is_active():
		return
	var new_position : Vector2 = get_preview_placement()
	# We only want to tween, if the card position is changing dramatically
	# such as when the info panels would exceed the width of the monitor, and therefore
	# we need to move them to the other side of the mouse cursor.
	if not _placement_initialized:
		yield(get_tree().create_timer(0.1), "timeout")
		rect_position = get_preview_placement()
	elif new_position.distance_to(rect_position) > 200:
		_tween_wait += 1
		# This is needed because the focus_info is wiped of all panels every time it's refreshed
		# so there's a small period of time where it's width is always 0
		# This causes the tween to activate twice back and forth every time a card hover is switched to
		# a new card. 
		# To avoid that, we put a small delay, to ensure the info panels have neen repopulated
		if _tween_wait > 10:
			_tween_wait = 0
			_tween.interpolate_property(self, "rect_position", rect_position, new_position, 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)
			_tween.start()
#			print_debug([preview_card, get_preview_placement()])
	else:
		rect_position = new_position
	focus_info.rect_min_size.x = 0.0
	focus_info.rect_size.x = 0.0
	focus_info.rect_position.y = 0
	focus_info.rect_position.x = preview_card.canonical_size.x * preview_card.preview_scale * cfc.curr_scale
	if not _placement_initialized:
		_placement_initialized = true
		emit_signal("placement_initialized")

	
# Figures out where to place the card preview in respect to the player's mouse.
func get_preview_placement() -> Vector2:
	# warning-ignore:unassigned_variable
	var ret : Vector2
	var focus_panel_offset = 0
	var card_size : Vector2 = preview_card.canonical_size * preview_card.preview_scale * cfc.curr_scale
	# If the card width is to small, we will place the info panels instead to the left of the card preview
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
			+ card_size.y
	var focus_offscreen_y = get_global_mouse_position().y + focus_info.rect_size.y
	if card_offscreen_y > focus_offscreen_y\
			and is_instance_valid(preview_card)\
			and card_offscreen_y > get_viewport().size.y:
		ret.y = get_viewport().size.y\
				- card_size.y\
				+ 30
	elif card_offscreen_y < focus_offscreen_y\
			and focus_offscreen_y > get_viewport().size.y:
		ret.y = get_viewport().size.y\
				- focus_info.rect_size.y + 30
	else:
		ret.y = get_global_mouse_position().y + 30
#	print_debug(ret)
	return(ret)


# Instances a card object. Populates it with the card details
# Then displays it in the popup.
# The variable passed can be a card name, or a card instance.
# If it's a card instance, it will be added to this node as a child directly.
func show_preview_card(card) -> void:
	if not has_preview_card():
		if typeof(card) == TYPE_STRING:
			preview_card = cfc.instance_card(card)
		else:
			preview_card = card
			preview_card.position = Vector2(0,0)
			preview_card.scale = Vector2(1,1)
		add_child(preview_card)
		# It's necessary we do this here because if we only we it during
		# the process, the card will appear to teleport
		if CFConst.VIEWPORT_FOCUS_ZOOM_TYPE == "resize":
			preview_card.resize_recursively(preview_card._control, preview_card.preview_scale * cfc.curr_scale)
			preview_card.card_front.scale_to(preview_card.preview_scale * cfc.curr_scale)
		cfc.ov_utils.populate_info_panels(preview_card,focus_info)
		call_deferred("_set_placement")
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
	_visible = true
	if _placement_initialized:
		modulate.a = 1



# Hides currently shown card.
# We're modulating to 0 instead of hide() because that messes with the rich text labels formatting
func hide_preview_card() -> void:
	modulate.a = 0
	
	_visible = false

func _on_placement_initialized() -> void:
	if _visible:
		modulate.a = 1

# We want to recreate the popup after the viewport size has changed
# As otherwise its elements may end up messed up
func _on_viewport_resized() -> void:
	if is_instance_valid(preview_card):
		preview_card.queue_free()


# Returns true if the preview_card variable has a valid Card instance
# else returns false
func has_preview_card() -> bool:
	return(is_instance_valid(preview_card))
