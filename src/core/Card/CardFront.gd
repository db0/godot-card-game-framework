# This class contains details about layout of the card front and the various
# labels which compose it.
#
# It also contains methods to adjust the text of the various labels,
# while keeping it inside its rect area.
class_name CardFront
extends Panel


# Maps the location of the card front labels so that they're findable even when
# The card front is customized for games of different needs
# Each card_front scene should have its own script extending this class
# which set the dictionary to map to the necessary nodes
#
# See "res://src/custom/CGFCardFront.gd" for an example.
var card_labels := {}
# Simply points to the container which holds all the labels
var _card_text
# Stores the amount of adjustment that has happened to the height of all
# labels, so that they fit their required text. This adjustment is then
# reversed on the compensation_label.
var _rect_adjustment := 0.0
# This dictionary defines how much more a text field is allowed
# to expand their rect in order to fit its text before shrinking its font size.
#
# The defaults of 1 means the text will shrink until it all fits within
# the originally defined rect of the label.
#
# This is useful for things like card names, where it's preferable to expand
# The title rect, instead of reducing the name's font size too much.
#
# You have to be careful with this field, as allowing too much expansion will
# lead to cards with a lot of text, having it overflow their boundaries
#
# This dictionary is set inside the script extending this class
# according to the needs of the labels defined within.
var text_expansion_multiplier : Dictionary
# If the card text is about to exceed the card's rect due to too much
# expansion of a label using text_expansion_multiplier, then the
# label specified in this var, will be shrunk extra to compensate.
#
# This string is set inside the script extending this class
# according to the needs of their labels defined within.
var compensation_label: String
# It stores the font sizes as required by the developer. We keep it stored
# In order to be able to compare against it during scale_to()
#
# This should be set by the develop in the script extending this for the card front
var original_font_sizes : Dictionary
# The font sizes as modified by the scale_to() method
var font_sizes : Dictionary
# The minimum label sizes. This is used by set_label_text() to calculate
# how much to shrink a label to fit within its current rect.
#
# This should be set by the develop in the script extending this for the card front
var card_label_min_sizes : Dictionary
# Stores the amount each font has been scaled to. We use this as a sort of
# boolean in order to avoid scaling the font again and again during process.
var scaled_fonts : Dictionary


# Stores a reference to the Card that is hosting this node
onready var card_owner = get_parent().get_parent()


# Set a label node's text.
# As the string becomes longer, the font size becomes smaller
func set_label_text(node: Label, value):
	var working_value: String
	# If the label node has been set to uppercase the text
	# Then we need to work off-of uppercased text value
	# otherwise our calculation will be off and we'll
	# end up extending the rect_size.y anyway
	if node.uppercase:
		working_value = value.to_upper()
	else:
		working_value = value
	_capture_original_font_size(node)
	# We do not want some fields, like the name, to be too small.
	# see CardConfig.TEXT_EXPANSION_MULTIPLIER documentation
	var allowed_expansion = text_expansion_multiplier.get(node.name,1)
	var adjust_size : float
	# There is always one specified label that compensates for other nodes
	# increasing or decreasing their y-rect.
	if node.name in compensation_label:
		adjust_size = _rect_adjustment
	var label_size = node.rect_min_size
	var label_font := get_card_label_font(node)
	# We always start shrinking the size, starting from the original size.
	label_font.size = font_sizes[node.name]
	var line_height = label_font.get_height()
	# line_spacing should be calculated into rect_size
	var line_spacing = node.get("custom_constants/line_spacing")
	if not line_spacing:
		line_spacing = 3
	# This calculates the amount of vertical pixels the text would take
	# once it was word-wrapped.
	var label_rect_y = label_font.get_wordwrap_string_size(
			working_value, label_size.x).y \
			/ line_height \
			* (line_height + line_spacing) \
			- line_spacing
	# If the y-size of the wordwrapped text would be bigger than the current
	# available y-size foir this label, we reduce the text, until we
	# it's small enough to stay within the boundaries
	while label_rect_y > label_size.y * allowed_expansion - adjust_size:
		label_font.size = label_font.size - 1
		if label_font.size < 3:
			label_font.size = 2
			break
		label_rect_y = label_font.get_wordwrap_string_size(
				working_value,label_size.x).y \
				/ line_height \
				* (line_height + line_spacing) \
				- line_spacing
	# If we allowed the card to expand its initial rect_size.y
	# we need to compensate somewhere by reducing another label's size.
	# We store the amount we increased in size from the
	# initial amount,m for this purpose.
	if label_rect_y > label_size.y:
		_rect_adjustment += label_rect_y - label_size.y
	if working_value == "":
		_rect_adjustment -= node.rect_size.y
		node.visible = false
	set_card_label_font(node, label_font)
	node.rect_min_size = label_size
	node.text = value
	# After any adjustmen of labels, we make sure the compensation_label font size
	# is adjusted again, if needed, to avoid exceeding the card borders.
	if compensation_label != ''\
			and not node.name in compensation_label\
			and _rect_adjustment != 0.0:
		set_label_text(card_labels[compensation_label], card_labels[compensation_label].text)


# Returns the font used by the current label
#
# We use an external function to get the font, to allow it to be overriden
# by classes extending this, to allow them to use their own methods
# (e.g. based on themes)
func get_card_label_font(label: Label) -> Font:
	return(label.get("custom_fonts/font").duplicate())


# Sets the font to be used by the current label
#
# We use an external function to get the font, to allow it to be overriden
# by classes extending this, to allow them to use their own methods
# (e.g. based on themes)
func set_card_label_font(label: Label, font: Font) -> void:
	label.set("custom_fonts/font", font)


# We use this as an alternative to scaling the card using the "scale" property.
# This is typically used in the viewport focus only, to keep the text legible
# because scaling the card starts distoring the font.
#
# For gameplay purposes (i.e. scaling while on the table etc),
# we keep using the .scale property, as that handles the Area2D size as well.
#
# Typically each game would override this function to fit its layout.
func scale_to(scale_multiplier: float) -> void:
	for l in card_labels:
		var label : Label = card_labels[l]
		if label.rect_min_size != card_label_min_sizes[l] * scale_multiplier:
			label.rect_min_size = card_label_min_sizes[l] * scale_multiplier
			font_sizes[l] = original_font_sizes.get(l) * scale_multiplier
	for l in card_labels:
		if scaled_fonts.get(l) != scale_multiplier:
			var label : Label = card_labels[l]
			set_label_text(label, label.text)
			scaled_fonts[l] = scale_multiplier


# Stores the original font size this label had.
# We use this to start shrinking the label from this size, which allows us to
# also increase it's size when its text changes to be smaller.
func _capture_original_font_size(label: Label) -> void:
	if not font_sizes.get(label.name):
		font_sizes[label.name] = original_font_sizes[label.name]
