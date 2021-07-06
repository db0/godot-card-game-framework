class_name ManipulationButtons
extends VBoxContainer

export(PackedScene) var manipulation_button : PackedScene

# This variable hold definitions for which buttons to create on this card.
#
# The dictionary key is the button name, and the value is the text to add
# to the button label.
var needed_buttons: Dictionary
# We use this variable to check if buttons are active for performance reasons
var _are_active := true

onready var _tween = $Tween
# Hold the node which owns this node.
onready var owner_node = get_parent().get_parent()


func _ready() -> void:
	spawn_manipulation_buttons()


# Adds an amount of manipulation buttons to the card
func spawn_manipulation_buttons() -> void:
	for button_name in needed_buttons:
		var button = manipulation_button.instance()
		button.name = button_name
		button.text = needed_buttons[button_name]
		add_child(button)
		# We also connect each button to the ourselves
		# The method should exist in any script that extends this class
		button.connect("pressed",self,"_on_" + button.name + "_pressed")


# Detects when the mouse is still hovering over the buttons area.
#
# We need to detect this extra, because the buttons restart event propagation.
#
# This means that the Control parent, will send a mouse_exit signal
# when the mouse enter a button rect
# which will make the buttons disappear again.
#
# So we make sure buttons stay visible while the mouse is on top.
#
# This is all necessary as a workaround for
# https://github.com/godotengine/godot/issues/16854
#
# Returns true if the mouse is hovering any of the buttons, else false
func are_hovered() -> bool:
	var ret = false
	for button in get_children():
		if button as Button \
				and button.is_hovered() \
				and button.modulate.a == 1:
			ret = true
	return(ret)


# Changes the hosted button node mouse filters
#
# * When set to false, buttons cannot receive inputs anymore
#    (this is useful when a card is in hand or a pile)
# * When set to true, buttons can receive inputs again
func set_active(value = true) -> void:
	if _are_active == value:
		return
	_are_active = value
	var button_filter := 1
	# We also want the buttons disabled while the card is being targeted
	# with a tarteting arrow.
	# We do not want to activate the buttons when a player is trying to
	# select the card for an effect.
	if not value or owner_node.highlight.modulate == CFConst.TARGET_HOVER_COLOUR:
		button_filter = 2
	# We do a comparison first, to make sure we avoid unnecessary operations
	for button in get_children():
		if button as Button and button.mouse_filter != button_filter:
			button.mouse_filter = button_filter
	# When we deactivate the buttons, we ensure they're hidden
	set_alpha(int(value))



# Sets one specific button to be (in)visible (and thus active) on demand
func set_button_visible(button_name: String, value: bool) -> void:
	if has_node(button_name):
		get_node(button_name).visible = value


# Allows the buttons to appear gracefully
func set_alpha(value := 1) -> void:
	if value != modulate.a and not _tween.is_active():
		_tween.remove_all()
		_tween.interpolate_property(
				self,'modulate:a',
				modulate.a, value, 0.25,
				Tween.TRANS_SINE, Tween.EASE_IN)
		_tween.start()
