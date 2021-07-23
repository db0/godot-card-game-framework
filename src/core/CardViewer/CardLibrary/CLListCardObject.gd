# A container for a card instance to be placed in a Card Library
class_name CLListCardObject
extends CVListCardObject


# Controls how big icons have to be when embedded in card library card text
var _icon_size := '15x15'


# Prepares the entry for a single card in the card library. The entry adds to
# The display of the card's Name and Type, also all the other card properties.
# If the card text is rich text, it will also be formatted as bbcode.
func setup(_card_name: String) -> void:
	.setup(_card_name)
	for p in card_properties:
		var property: String = p
		if not property.begins_with('_')\
				and property != CardConfig.SCENE_PROPERTY:
			var new_label := RichTextLabel.new()
			new_label.name = property
			new_label.rect_min_size.x = 100
			new_label.bbcode_enabled = true
			new_label.scroll_active = false
			new_label.fit_content_height = true
#			new_label.autowrap = true
			var format = _get_bbcode_format()
			var bbcode_format := {}
			bbcode_format["icon_size"] = _icon_size
			for key in format:
				format[key] = format[key].format(bbcode_format)
			if property in CardConfig.PROPERTIES_ARRAYS:
				new_label.bbcode_text = CFUtils.array_join(card_properties[property],
							CFConst.ARRAY_PROPERTY_JOIN)
			else:
				new_label.bbcode_text = str(card_properties[property]).format(format)
			add_child(new_label)

# Fetches the bbcode formating used for this game
func _get_bbcode_format() -> Dictionary:
	return(CardConfig.CARD_BBCODE.duplicate())
