# Creates a GridContainer in which cards can be placed organized next
# to each other.
#
# To use this scene properly, create an inherited scene,
# then add as many instanced BoardPlacementSlots as you need this grid to hold
#
# Adjust its highlight colour and the amount of columns it should have as well
#
# The BoardPlacementSlots will adjust to card_size on runtime, but
# If you want to visually see on the editor your result
class_name BoardPlacementGrid
extends Control

# Used to add new BoardPlacementSlot instances to grids. We have to add the consts
# together before passing to the preload, or the parser complains
const _SLOT_SCENE_FILE = CFConst.PATH_CORE + "BoardPlacementSlot.tscn"
const _SLOT_SCENE = preload(_SLOT_SCENE_FILE)

# Set the highlight colour for all contained BoardPlacementSlot slots
export(Color) var highlight = CFConst.TARGET_HOVER_COLOUR
# If set to true, the grid will automatically add more slots
# when find_available_slot() is used and there's no more available slots
# (only useful when using the ScriptingEngine)
export var auto_extend := false
# Used to adjust the grid according to the card size that will be put into it.
# This size should match the
export var card_size := CFConst.CARD_SIZE
export var card_play_scale := CFConst.PLAY_AREA_SCALE

# Sets a custom label for this grid
onready var name_label = $Control/Label

func _ready() -> void:
	rect_size = (card_size * card_play_scale) + Vector2(4,4)
	# We ensure the separation of the grid slots is always 1 pixel larger
	# Than the radius of the mouse pointer collision area.
	# This ensures that we don't highlight 2 slots at the same time.
	$GridContainer.set("custom_constants/vseparation",
			MousePointer.MOUSE_RADIUS * 2 + 1)
	$GridContainer.set("custom_constants/hseparation",
			MousePointer.MOUSE_RADIUS * 2 + 1)
	if not name_label.text:
		name_label.text = name


# If a BoardPlacementSlot object child in this container is highlighted
# Returns the object. Else returns null
func get_highlighted_slot() -> BoardPlacementSlot:
	var ret_slot: BoardPlacementSlot = null
	for slot in get_all_slots():
		if slot.is_highlighted():
			ret_slot = slot
	return(ret_slot)


# Returns the slot at the specified index.
func get_slot(idx: int) -> BoardPlacementSlot:
	var ret_slot: BoardPlacementSlot = $GridContainer.get_child(idx)
	return(ret_slot)


# Adds new placement slot to the grid.
# Returns the slot object
func add_slot() -> BoardPlacementSlot:
	var new_slot : BoardPlacementSlot = _SLOT_SCENE.instance()
	$GridContainer.add_child(new_slot)
	return(new_slot)


# Returns a slot that is not currently occupied by a card
func find_available_slot() -> BoardPlacementSlot:
	var found_slot : BoardPlacementSlot
	if not get_available_slots().empty():
		found_slot = get_available_slots().front()
	elif auto_extend:
		found_slot = add_slot()
	return(found_slot)


# Returns an array containing all the BoardPlacementSlot nodes
func get_all_slots() -> Array:
	return($GridContainer.get_children())


# Returns the amount of BoardPlacementSlot contained.
func get_slot_count() -> int:
	return(get_all_slots().size())


# Returns an array with all slots not occupied by a card
func get_available_slots() -> Array:
	var available_slots := []
	for slot in get_all_slots():
		if not slot.occupying_card:
			available_slots.append(slot)
	return(available_slots)


# Returns the count of all available slots
func count_available_slots() -> int:
	return(get_available_slots().size())
