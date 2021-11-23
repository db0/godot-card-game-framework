# This class is used to simply display all cards available in the game
class_name CardLibrary
extends CardViewer

# The default embedded image size inside RichTextLabels
export var icon_size := 15
# The default width a card property should have in the card library
# Card Name is always set to take all leftover space
export var default_property_width := 150
# Each key in this dict is a card property, and each value is how wide
# the property for this label should be. Useful to limit the size of
# properties which are just single integers
export var property_width_exceptions := {}

func _ready() -> void:
	if property_width_exceptions.has(CardConfig.SCENE_PROPERTY):
		_card_type_header.rect_min_size.x = property_width_exceptions[CardConfig.SCENE_PROPERTY]
	else:
		_card_type_header.rect_min_size.x = default_property_width

# Populates the list of available cards, with all defined cards in the game
func populate_available_cards() -> void:
	.populate_available_cards()
	var card_props :Dictionary = _available_cards.get_child(0).card_properties
	for p in card_props:
		var property: String = p
		# Properties with underscore are not shown
		# and the SCENE_PROPERTY is preset
		if not property.begins_with('_')\
				and property != CardConfig.SCENE_PROPERTY:
			var new_label := RichTextLabel.new()
			if property_width_exceptions.has(property):
				new_label.rect_min_size.x = property_width_exceptions[property]
			else:
				new_label.rect_min_size.x = default_property_width
			new_label.rect_min_size.y = 20
			new_label.name = property
			new_label.bbcode_text = property
			new_label.bbcode_enabled = true
			new_label.scroll_active = false
			new_label.fit_content_height = false
			new_label.custom_effects = custom_rich_text_effects
			_card_headers.add_child(new_label)
