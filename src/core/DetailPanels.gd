# Allows to add extra info for cards under their focus popups.
# Typically used in the deckbuilder or in the viewport focus
#
# After adding this node, adjust the info_panel_scene in its details
# and have it point to your custom info scene.
class_name DetailPanels
extends GridContainer

export(PackedScene) var info_panel_scene
# How many panels need to be added before adding an extra column to the grid
export(int) var panel_column_threshold := 6

# This dictionary holds all detail scenes added to the list
# Each entry is an id for the detail (typically its tag or keyword)
# and the values are a pointer to the node.
var existing_details := {}
# Returns how many details are currently visible for this card
var visible_details setget ,get_visible_details


func _ready() -> void:
	pass

# Sets up the illustration detail, as it should always exist first
func setup() -> void:
	# Because we want the illustration to always be the first detail
	add_info("illustration", '')
	hide_illustration()


# Hides the illustration detail
func hide_illustration() -> void:
	if not existing_details.has("illustration"):
		return
	existing_details["illustration"].visible = false


# Shows the illustration detail. This is different from the usual
# details, as we allow the illustration text to change every time.
func show_illustration(text: String) -> void:
	if not existing_details.has("illustration"):
		return
	existing_details["illustration"].visible = true
	existing_details["illustration"].get_node("Details").text = text


# Hides all created info. Typically used before showing the specific
# ones needed for this card
func hide_all_info() -> void:
	for known_info in existing_details:
		existing_details[known_info].visible = false
	rect_size = Vector2(0,0)


# Adds a new info node. It requires an id for that node
# (Typically the relevant tag or keyword)
#
# If this ID has already been setup, it will just be made visible
# If not, It will instance the scene and set up its text.
func add_info(
		id: String, 
		text: String, 
		info_scene : PackedScene = null, 
		requires_refresh := false) -> void:
	if existing_details.has(id) and not requires_refresh:
		existing_details[id].visible = true
	else:
		var new_info_panel : Node
		if existing_details.has(id) and requires_refresh:
			new_info_panel = existing_details.get(id)
			new_info_panel.visible = true
		else:
			if info_scene != null:
				new_info_panel = info_scene.instance()
			else:
				new_info_panel = info_panel_scene.instance()
			add_child(new_info_panel)
			existing_details[id] = new_info_panel
		var label = new_info_panel.get_node("Details")
		if label as RichTextLabel:
			label.bbcode_text = text
		else:
			label.text = text
	var child_count := 0
	for info_panel in get_children():
		if info_panel.visible: 
			child_count += 1
	if existing_details.has("illustration"):
		existing_details["illustration"].raise()
	columns = 1 + floor(child_count / panel_column_threshold)


# Getter for visible_details
func get_visible_details() -> int:
	var visible_count := 0
	for node in get_children():
		if node.visible:
			visible_count += 1
	return(visible_count)
