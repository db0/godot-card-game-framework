class_name CardLibrary
extends CardViewer


# Populates the list of available cards, with all defined cards in the game
func populate_available_cards() -> void:
	.populate_available_cards()
	var card_props :Dictionary = _available_cards.get_child(0).card_properties
	for p in card_props:
		var property: String = p
		if not property.begins_with('_')\
				and property != CardConfig.SCENE_PROPERTY:
			var new_label := Label.new()
			new_label.name = property
			new_label.text = property
			new_label.rect_min_size.x = 100
			_card_headers.add_child(new_label)
