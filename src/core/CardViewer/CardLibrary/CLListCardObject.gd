class_name CLListCardObject
extends CVListCardObject

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
			bbcode_format["icon_size"] = '12x12'
			for key in format:
				format[key] = format[key].format(bbcode_format)
			if property in CardConfig.PROPERTIES_ARRAYS:
				new_label.bbcode_text = CFUtils.array_join(card_properties[property],
							CFConst.ARRAY_PROPERTY_JOIN)
			else:
				new_label.bbcode_text = str(card_properties[property]).format(format)
			add_child(new_label)

func _get_bbcode_format() -> Dictionary:
	return(CardConfig.CARD_BBCODE.duplicate())
