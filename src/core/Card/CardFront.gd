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
var resizing_labels := []

var font_thread: Thread


# Stores a reference to the Card that is hosting this node
onready var card_owner = get_parent().get_parent().get_parent()


## Thread must be disposed (or "joined"), for portability.
#func _exit_tree():
#	font_thread.wait_to_finish()

# Set a label node's text.
# As the string becomes longer, the font size becomes smaller
func set_label_text(node: Label, value, scale: float = 1):
#	while font_thread and font_thread.is_active():
#		yield(get_tree(), "idle_frame")
#	font_thread = Thread.new()
## warning-ignore:return_value_discarded
#	font_thread.start(self, "_set_label_text", [node,value], Thread.PRIORITY_LOW)
	if node in resizing_labels:
		return
	resizing_labels.append(node)
	value = _check_for_replacements(node, value)
	var label_font :Font = get_card_label_font(node)
#	print_debug(scaled_fonts.get(node.name, 1))
	var cached_font_size = get_cached_font_size(node,value,scale)
	if cached_font_size:
		label_font.size = cached_font_size
	else:
		# We add a yield here to allow the calling function to continue
		# and thus avoid the game waiting for the label to resize
		yield(get_tree(), "idle_frame")
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
		var line_spacing = node.get("custom_constants/line_spacing")
		if not line_spacing:
			line_spacing = 3
		var starting_font_size: int = font_sizes[node.name]
		label_font.size = starting_font_size
		var font_adjustment := _adjust_font_size(label_font, working_value, node.rect_min_size, line_spacing)
	#	if  node.name == "Abilities": font_adjustment = -17
		# We always start shrinking the size, starting from the original size.
#		print_debug(scaled_fonts.get(node.name, 1))
		_cache_font_size(node,value,starting_font_size + font_adjustment,scale)
		label_font.size = starting_font_size + font_adjustment
	set_card_label_font(node, label_font)
	node.text = value
	resizing_labels.erase(node)


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
			while card_labels[l] in resizing_labels:
				yield(get_tree(), "idle_frame")
			if card_labels[l] as RichTextLabel:
				var label : RichTextLabel = card_labels[l]
				call_deferred("set_rich_label_text",label, label.bbcode_text, true, scale_multiplier)
			else:
				var label : Label = card_labels[l]
				call_deferred("set_label_text",label, label.text, scale_multiplier)



# Set a label node's bbcode text.
# As the string becomes longer, the font size becomes smaller
func set_rich_label_text(node: RichTextLabel, value: String, is_resize := false, scale : float = 1):
	# We need to avoid other functions to trying to resize this label
	# while it's already resizing, as due to all the yields
	# it causes a mess
	if node in resizing_labels:
		return
	resizing_labels.append(node)
	value = _check_for_replacements(node, value)
	# This is used to hide a card with rich text while the rich text is resizing
	# This is because richtext cannot resize properly while invisible
	# Therefore we need to keep the front visible while the rich text label is resizing.
	# To avoid the player seeing the top card of their deck while this is happening
	# Or to see the font resizing in front of their eyes (due to all the yields)
	# we modulate the card front to 0.
	modulate.a = 0
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
	var cached_font_size = get_cached_font_size(node,value,scale)
	if cached_font_size:
		_set_card_rtl_fonts(node, label_fonts, cached_font_size)
		_assign_bbcode_text(node, value, cached_font_size)
	else:
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
		var _retries := 0
		var bbcode_height = node.get_content_height()
#		print_debug([bbcode_height, label_size.y])
		while bbcode_height == 0 or bbcode_height > 1000:
			_retries += 1
#			print_debug("{0} BBcode height:{1} retrying: {2}".format([card_owner.canonical_name, bbcode_height, _retries]))
			yield(get_tree(), "idle_frame")
			bbcode_height = node.get_content_height()
#			print_debug(["Retry", _retries, "Code Height", bbcode_height])
			if _retries >= 10:
				break
		# To save some time, we use the same trick we do in normal labels
		# where we reduce the font size to fits its rect
		# However unlike normal labels, we might have icons and different font sizes
		# which will not be taken into account.
		# Therefore this gives us the starting point, but further reduction might be
		# needed.
		if bbcode_height > label_size.y:
			font_adjustment = _adjust_font_size(label_fonts["normal_font"], node.text, label_size)
			_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
			yield(get_tree(), "idle_frame")
			bbcode_height = node.get_content_height()
#			print_debug(["Font Adjustment", font_adjustment, "Code Height", bbcode_height])
	#		print_debug(bbcode_height, ':', font_adjustment, ':', label_size.y)
		# If the reduction of font sizes when checking against the normal font
		# was not enough to bring the total rich label height into the rect.y we want
		# we use a while loop where we do the following in order
		# * reduce all rich-text font sizes by 1
		# * reset the bbcode text
		# * Wait for the next frame
		# * grab the new rich text height
		# Unitl the rich text height is smaller than the labels' rect size.
		var small_size_retries := 0
		while bbcode_height > label_size.y:
			font_adjustment -= 1
			_set_card_rtl_fonts(node, label_fonts, starting_font_size + font_adjustment)
			_assign_bbcode_text(node, value, starting_font_size + font_adjustment)
			yield(get_tree(), "idle_frame")
			bbcode_height = node.get_content_height()
#			print_debug(["Font Adjustment", font_adjustment, "Code Height", bbcode_height])
			_retries = 0
			while bbcode_height == 0 or bbcode_height > 1000:
				_retries += 1
#				print_debug("BBcode height:" + str(bbcode_height) + " retrying: " + str(_retries))
				yield(get_tree(), "idle_frame")
				bbcode_height = node.get_content_height()
				if _retries >= 10:
					break
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
			if starting_font_size + font_adjustment == 6:
				if small_size_retries <= 2:
					print_debug("WARN:CGF:{0} rich text label reached minimum size (6).\nRestarting font size calulcations retry: {4}\nstarting_font_size {1}\nbbcode_height: {2} > label_size.y: {3}".format(
							[card_owner.canonical_name, starting_font_size, bbcode_height, label_size.y, small_size_retries]))
					small_size_retries += 1
					font_adjustment = _adjust_font_size(label_fonts["normal_font"], node.text, label_size)
				else:
					break
		_cache_font_size(node,value,starting_font_size + font_adjustment, scale)
	modulate.a = 1
	resizing_labels.erase(node)


func _cache_font_size(label: Control, text: String, font_size: int, scale : float) -> void:
	var text_md5 =  text.md5_text()
	# We will store each label's font size in a key based on the card scale
	# The default scale being 1
	# It has to be a string because the Godot Json print converts ints to
	# Strings when saving to file
	var card_size = str(scale)
	if not cfc.font_size_cache.has(card_size):
		cfc.font_size_cache[card_size] = {}
	if not cfc.font_size_cache[card_size].has(label.name):
		cfc.font_size_cache[card_size][label.name] = {}
	cfc.font_size_cache[card_size][label.name][text_md5] = font_size
	cfc.set_font_cache()


func get_cached_font_size(label: Control, text: String, scale : float):
	var text_md5 =  text.md5_text()
	var card_size = str(scale)
	var cached_font_size = cfc.font_size_cache.get(card_size, {}).get(label.name, {}).get(text_md5)
	return(cached_font_size)

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
	if rtlabel == card_labels["Name"]:
		_add_title_bbcode(rtlabel)
	rtlabel.push_align(RichTextLabel.ALIGN_CENTER)
	# warning-ignore:return_value_discarded
	rtlabel.append_bbcode(bbcode_text.format(format))
	#	print_debug(bbcode_text.format(format))
	rtlabel.pop()
	if rtlabel == card_labels["Name"]:
		_pop_title_bbcode(rtlabel)


# Overridable function for extra formatting of titles/card names
func _add_title_bbcode(_rtlabel: RichTextLabel):
	pass

# Overridable function for extra formatting of titles/card names
func _pop_title_bbcode(_rtlabel: RichTextLabel):
	pass


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
			"title_font",
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
			"title_font",
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
	var label_rect_y = adjustment_font.get_wordwrap_string_size(
			text, label_size.x).y \
			/ line_height \
			* (line_height + line_spacing) \
			- line_spacing
	# If the y-size of the wordwrapped text would be bigger than the current
	# available y-size foir this label, we reduce the text, until we
	# it's small enough to stay within the boundaries
	while label_rect_y > label_size.y:
		adjustment -= 1
		adjustment_font.size = font.size + adjustment
		line_height = adjustment_font.get_height()
		label_rect_y = adjustment_font.get_wordwrap_string_size(
				text,label_size.x).y \
				/ line_height \
				* (line_height + line_spacing) \
				- line_spacing
		if adjustment_font.size < 5:
			break
	return(adjustment)


# Overridable function which allows values to be replaced on the fly
# when placed in the card front.
func _check_for_replacements(node, value):
	for repl_key in CardConfig.REPLACEMENTS:
		if node == card_labels[repl_key]:
			# This command will try to find a replacement for this value in the replacements
			# But will keep the existing value if none is found.
			value = CardConfig.REPLACEMENTS[repl_key].get(value, value)
	return(value)
