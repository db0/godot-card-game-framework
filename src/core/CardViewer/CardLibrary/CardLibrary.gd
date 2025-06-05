# This class is used to simply display all cards available in the game
class_name CardLibrary
extends CardViewer

# The default embedded image size inside RichTextLabels
@export var icon_size := 15
# The default width a card property should have in the card library
# Card Name is always set to take all leftover space
@export var default_property_width := 150
# Each key in this dict is a card property, and each value is how wide
# the property for this label should be. Useful to limit the size of
# properties which are just single integers
@export var property_width_exceptions := {}

func _ready() -> void:
	super._ready()
	if property_width_exceptions.has(CardConfig.SCENE_PROPERTY):
		_card_type_header.custom_minimum_size.x = property_width_exceptions[CardConfig.SCENE_PROPERTY]
	else:
		_card_type_header.custom_minimum_size.x = default_property_width
	set_list_entry_sizes()

## Populates the list of card properties as column headers
## Also sets t
func populate_available_cards() -> void:
	super.populate_available_cards()
	var card_props: Dictionary = _available_cards.get_child(0).card_properties
	for p in card_props:
		var property: String = p
		# Properties with underscore are not shown
		# and the SCENE_PROPERTY is preset
		if not property.begins_with('_')\
				and property != CardConfig.SCENE_PROPERTY:
			var new_label := RichTextLabel.new()
			if property_width_exceptions.has(property):
				new_label.custom_minimum_size.x = property_width_exceptions[property]
			else:
				new_label.custom_minimum_size.x = default_property_width
			new_label.custom_minimum_size.y = 20
			new_label.name = property
			new_label.text = property
			new_label.bbcode_enabled = true
			new_label.scroll_active = false
			#new_label.fit_content = false
			new_label.custom_effects = custom_rich_text_effects
			_card_headers.add_child(new_label)
	#for c: CLListCardObject in _available_cards.get_children():
		#c.property_width_exceptions = property_width_exceptions
		#c.default_property_width = default_property_width
	set_list_entry_sizes()

# Loop through the title column sizes, and set the card widths accordingly
# NOTE: Assume the column headers match the card headers
func set_list_entry_sizes() -> void:
	for i in range(_card_headers.get_children().size()):
		var col = _card_headers.get_child(i)
		#var width = col.size.x
		#var pos_x = col.position.x
		#var col_name = col.get_text()
		for card: CLListCardObject in _available_cards.get_children():
			assert(_card_headers.get_children().size() == card.get_children().size(), "Card has same number of entries as the list headers")
			var entry = card.get_child(i)
			#assert(col_name == str(entry.name), "Verify our assumption that the headers line up with the card labels")
			# get the relevant control for this column
			#var card: CLListCardObject = _available_cards.get_child(i)
			#card.get
			#card.size.x = width
			entry.size_flags_horizontal = col.size_flags_horizontal
			entry.custom_minimum_size.x = col.custom_minimum_size.x
			entry.size.x = col.size.x
			#entry.position.x = col.position.x
