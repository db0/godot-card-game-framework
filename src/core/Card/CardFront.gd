# This class contains details about layout of the card front and the various
# labels which compose it.
#
# It also contains methods to adjust the text of the various labels,
# while keeping it inside its rect area.
class_name CardFront
extends Panel

signal rt_resized

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
var bbcode_texts := {}
var rich_text_font_size_variations := {}
var rt_resizing := false



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
		if card_labels[compensation_label] as RichTextLabel:
			pass
#			print_debug(card_labels[compensation_label].text)
#			call_deferred("_adjust_rt_size", card_labels[compensation_label])
#			_adjust_rt_size(card_labels[compensation_label])
#			var ret = set_rich_label_text(card_labels[compensation_label], card_labels[compensation_label].bbcode_text, true)
#			if ret is GDScriptFunctionState:
#				ret = yield(ret, "completed")
		else:
			set_label_text(card_labels[compensation_label], card_labels[compensation_label].text)


# Returns the font used by the current label
#
# We use an external function to get the font, to allow it to be overriden
# by classes extending this, to allow them to use their own methods
# (e.g. based on themes)
func get_card_label_font(label: Label) -> Font:
	var theme : Theme = self.theme
	var label_font : Font
	if theme:
		label_font = theme.get_font("font", "Label").duplicate()
	else:
		label_font = label.get("custom_fonts/font").duplicate()
	return(label_font)


# Sets the font to be used by the current label
#
# We use an external function to get the font, to allow it to be overriden
# by classes extending this, to allow them to use their own methods
# (e.g. based on themes)
func set_card_label_font(label: Label, font: Font) -> void:
	label.add_font_override("font", font)


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
		font_sizes[l] = original_font_sizes.get(l) * scale_multiplier
	for l in card_labels:
		if scaled_fonts.get(l) != scale_multiplier:
			scaled_fonts[l] = scale_multiplier
			if card_labels[l] as RichTextLabel:
				var label : RichTextLabel = card_labels[l]
				if rt_resizing:
					yield(self, "rt_resized")
				call_deferred("set_rich_label_text",label, label.bbcode_text, true)
			else:
				var label : Label = card_labels[l]
				set_label_text(label, label.text)



# Set a label node's bbcode text.
# As the string becomes longer, the font size becomes smaller
func set_rich_label_text(node: RichTextLabel, value: String, is_resize := false):
	# We need to avoid other functions to trying to resize this label
	# while it's already resizing, as due to all the yields
	# it causes a mess
	if rt_resizing:
		return
	rt_resizing = true
	# This is used to hide a card with rich text while the rich text is resizing
	# This is because richtext cannot resize properly while invisible
	# Therefore we need to keep the front visible while the rich text label is resizing.
	# To avoid the player seeing the top card of their deck while this is happening
	# Or to see the font resizing in front of their eyes (due to all the yields)
	# we modulate the card front to 0.
	modulate.a = 0
	var adjust_size : float
	var allowed_expansion = text_expansion_multiplier.get(node.name,1)
	# There is always one specified label that compensates for other nodes
	# increasing or decreasing their y-rect.
	if node.name in compensation_label:
		adjust_size = _rect_adjustment
	# I had to add this cache, because I cannot seem to get the bbcode_text
	# out of the label once I set it
	if not bbcode_texts.has(node) and not is_resize:
		bbcode_texts[node] = value
	elif is_resize:
		if not bbcode_texts.has(node):
			return
		value = bbcode_texts[node]
	var label_fonts := _get_card_rtl_fonts(node)
	# We always start shrinking the size, starting from the original size.
	_capture_original_font_size(node)
	_capture_rt_font_size_variations(node)
	var starting_font_size: int = font_sizes[node.name]
	var font_adjustment:= 0
#	label_font.size = font_sizes[node.name]
	var label_size = node.rect_min_size
	_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
	_assign_bbcode_text(node, value, starting_font_size + font_adjustment)
	# Rich Text has no way to grab its total size without setting the bbcode first
	# After we set the bbcode, we need to wait for the next frame for the label to adjust
	# and then we can grab its height
	yield(get_tree(), "idle_frame")
	var bbcode_height = node.get_content_height()
	# To save some time, we use the same trick we do in normal labels
	# where we reduce the font size to fits its rect
	# However unlike normal labels, we might have icons and different font sizes
	# which will not be taken into account.
	# Therefore this gives us the starting point, but further reduction might be
	# needed.
	if bbcode_height > label_size.y * allowed_expansion - adjust_size:
		font_adjustment = _adjust_font_size(label_fonts["normal_font"], node.text, label_size)
		_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
		yield(get_tree(), "idle_frame")
		bbcode_height = node.get_content_height()
	# If the reduction of font sizes when checking against the normal font
	# was not enough to bring the total rich label height into the rect.y we want
	# we use a while loop where we do the following in order
	# * reduce all rich-text font sizes by 1
	# * reset the bbcode text
	# * Wait for the next frame
	# * grab the new rich text height
	# Unitl the rich text height is smaller than the labels' rect size.
	while bbcode_height > label_size.y * allowed_expansion - adjust_size:
		font_adjustment -= 1
		_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
		_assign_bbcode_text(node, value, starting_font_size + font_adjustment)
		yield(get_tree(), "idle_frame")
		bbcode_height = node.get_content_height()
		# If we don't keep the card front face-up while setting the RTL,
		# The bbcode_height will be returned as either 0 or 1000 after setting the
		# bbcode_text. Regardless of how long we wait.
		# The below snipper was debugging code to keep the code waiting to resize
		# until the card was turned face-up
#		while bbcode_height == 0 or bbcode_height > 1000:
#			_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
#			_assign_bbcode_text(node, value, starting_font_size + font_adjustment)
#			yield(get_tree(), "idle_frame")
#			bbcode_height = node.get_content_height()
		if starting_font_size + font_adjustment == 4:
			break
	# If we allowed the card to expand its initial rect_size.y
	# we need to compensate somewhere by reducing another label's size.
	# We store the amount we increased in size from the
	# initial amount,m for this purpose.
	if bbcode_height > label_size.y:
		_rect_adjustment += bbcode_height - label_size.y
	if value == "":
		_rect_adjustment -= node.rect_size.y
		node.visible = false
	rt_resizing = false
	modulate.a = 1
	emit_signal("rt_resized")


# Stores the original font size this label had.
# We use this to start shrinking the label from this size, which allows us to
# also increase it's size when its text changes to be smaller.
func _capture_original_font_size(label) -> void:
	if not font_sizes.has(label.name):
		font_sizes[label.name] = original_font_sizes[label.name]


func _assign_bbcode_text(rtlabel: RichTextLabel, bbcode_text : String, font_size: int) -> void:
	var format = _get_bbcode_format()
	rtlabel.clear()
	var bbcode_format := {}
	var icon_size = font_size - 2
	bbcode_format["icon_size"] = '{icon_size}x{icon_size}'.format({"icon_size":icon_size})
	for key in format:
		format[key] = format[key].format(bbcode_format)
	rtlabel.push_align(RichTextLabel.ALIGN_CENTER)
	rtlabel.append_bbcode(bbcode_text.format(format))
#	print_debug(bbcode_text.format(format))
	rtlabel.pop()


func _get_bbcode_format() -> Dictionary:
	return(CardConfig.CARD_BBCODE.duplicate())


# Goes through a rich text label, and retrieves all fonts used to define it.
func _get_card_rtl_fonts(label: RichTextLabel) -> Dictionary:
	var theme : Theme = self.theme
	var all_rt_fonts:= {}
	var label_font : Font
	for font_type in [
			"normal_font",
			"italics_font",
			"bold_font",
			"bold_italics_font",
			"mono_font"]:
		if theme:
			label_font = theme.get_font(font_type, "RichTextLabel").duplicate()
			if label_font:
				all_rt_fonts[font_type] = label_font
		else:
			label_font = label.get("custom_fonts/" + font_type).duplicate()
			if label_font:
				all_rt_fonts[font_type] = label_font
	return(all_rt_fonts)


# Stores the difference of each RT font, compared to the "normal_font"
# We use the normal_font as the baseline. So if normal font was 15 and italic is 14
# if we resize normal font to 10. Italic should be resized to 9
func _capture_rt_font_size_variations(label: RichTextLabel) -> void:
	if rich_text_font_size_variations.has(label):
		return
	var fvars := {}
	var label_fonts := _get_card_rtl_fonts(label)
	for font_type in [
			"normal_font",
			"italics_font",
			"bold_font",
			"bold_italics_font",
			"mono_font"]:
		fvars[font_type] = label_fonts[font_type].size - label_fonts["normal_font"].size
	rich_text_font_size_variations[label] = fvars


# Sets all fonts by the current rich text label
# adjusted in relation to the normal font.
func _set_card_rtl_fonts(label: RichTextLabel, fonts_dict: Dictionary, new_size: int) -> void:
	for font_type in fonts_dict:
		fonts_dict[font_type].size = new_size + rich_text_font_size_variations[label][font_type]
		label.add_font_override(font_type, fonts_dict[font_type])


# figures out how much a font size has to be reduced, in order to fit
# in the specified rect.
#
# Returns the reductio from the provided font size that will have to be applied.
func _adjust_font_size(
		font: Font,
		text: String,
		label_size: Vector2,
		line_spacing := 3) -> int:
	var adjustment_font := font.duplicate(true)
	var line_height = font.get_height()
	var adjustment := 0
	# line_spacing should be calculated into rect_size
	# This calculates the amount of vertical pixels the text would take
	# once it was word-wrapped.
	var label_rect_y = font.get_wordwrap_string_size(
			text, label_size.x).y \
			/ line_height \
			* (line_height + line_spacing) \
			- line_spacing
	# If the y-size of the wordwrapped text would be bigger than the current
	# available y-size foir this label, we reduce the text, until we
	# it's small enough to stay within the boundaries
	while label_rect_y > label_size.y:
		adjustment -= 1
		adjustment_font.size = adjustment_font.size + adjustment
		label_rect_y = adjustment_font.get_wordwrap_string_size(
				text,label_size.x).y \
				/ line_height \
				* (line_height + line_spacing) \
				- line_spacing
		if adjustment_font.size < 5:
			break
	return(adjustment)
