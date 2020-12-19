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
# Stores the amount of
var _extra_text_shrink := 0.0
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
var shrink_label: String


# Stores a reference to the Card that is hosting this node
onready var card_owner = get_parent().get_parent()


# Set a label node's text.
# As the string becomes longer, the font size becomes smaller
func set_label_text(node: Label, value):
	# We do not want some fields, like the name, to be too small.
	# see CardConfig.TEXT_EXPANSION_MULTIPLIER documentation
	var allowed_expansion = text_expansion_multiplier.get(node.name,1)
	var shrink_size : float
	# If this node is the specified node that compensates for other nodes
	# increasing their y-rect, then it has less y-space for itself according
	# to the amount the others increased.
	if node.name in shrink_label:
		shrink_size = _extra_text_shrink
	var label_size = node.rect_min_size
	var label_font = node.get("custom_fonts/font").duplicate()
	var line_height = label_font.get_height()
	# line_spacing should be calculated into rect_size
	var line_spacing = node.get("custom_constants/line_spacing")
	if not line_spacing:
		line_spacing = 3
	# This calculates the amount of vertical pixels the text would take
	# once it was word-wrapped.
	var label_rect_y = label_font.get_wordwrap_string_size(
			value, label_size.x).y \
			/ line_height \
			* (line_height + line_spacing) \
			- line_spacing
	# If the y-size of the wordwrapped text would be bigger than the current
	# available y-size foir this label, we reduce the text, until we
	# it's small enough to stay within the boundaries
	while label_rect_y > label_size.y * allowed_expansion - shrink_size:
		label_font.size = label_font.size - 1
		if label_font.size < 3:
			label_font.size = 2
			break
		label_rect_y = label_font.get_wordwrap_string_size(
				value,label_size.x).y \
				/ line_height \
				* (line_height + line_spacing) \
				- line_spacing
	# If we allowed the card to expand its initial rect_size.y
	# we need to compensate somewhere by reducing another label's size.
	# We store the amount we increased in size from the
	# initial amount,m for this purpose.
	if label_rect_y > label_size.y:
		_extra_text_shrink = label_rect_y - label_size.y
	node.set("custom_fonts/font", label_font)
	node.rect_min_size = label_size
	node.text = value

