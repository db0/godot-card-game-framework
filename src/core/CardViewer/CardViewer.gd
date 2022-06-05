# The Card Viewer is a basic class which is responsible for displaying
# all cards available in the game, either for preview, or for deckbuilding
#
# It is meant to be extended.
class_name CardViewer
extends PanelContainer

# The path to the ListCardObject scene. This has to be defined explicitly
# here, in order to use it in its preload, otherwise the parser gives an error
const _LIST_CARD_OBJECT_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVListCardObject.tscn"
const _LIST_CARD_OBJECT_SCENE = preload(_LIST_CARD_OBJECT_SCENE_FILE)
# The path to the GridCardObject scene.
const _GRID_CARD_OBJECT_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVGridCardObject.tscn"
const _GRID_CARD_OBJECT_SCENE = preload(_GRID_CARD_OBJECT_SCENE_FILE)
const _FILTER_BUTTON_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVFilterButton.tscn"
const _FILTER_BUTTON_SCENE = preload(_FILTER_BUTTON_SCENE_FILE)
const _INFO_PANEL_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVInfoPanel.tscn"
const _INFO_PANEL_SCENE = preload(_INFO_PANEL_SCENE_FILE)
const _SHOW_ALL_ICON_FILE = CFConst.PATH_CORE\
		+ "CardViewer/open-book.png"
const _SHOW_ALL_ICON = preload(_SHOW_ALL_ICON_FILE)

# Set a property name defined in the cards. The deckbuilder will provide
# one button per distinct property of that name
# it discovers in your card base. This buttons can be toggled on/off
# for quick filtering
#
# Only supports string properties. No tags or integers. Also, all cards
# Should have some value in this property. It is suggested this functionality
# is only used on properties with few distinct values.
#
# Also, if more than 8 distrinct properties are found, this functionality
# will be skipped.
export var filter_button_properties := ["Type"]
# If a value in a card property is in this list, the Deckbuilder will call its
# value_generation method to attempt to generate the value according to the
# game's design.
# Make sure that the values specified will never match normal values for that
# property.
export var generation_keys := []
# See CardConfig.REPLACEMENTS. This allows for extra replacements in the card
# Viewer, if needed.
export var replacements := CardConfig.REPLACEMENTS
# The custom scene which displays the card when its name is hovered.
export var info_panel_scene = _INFO_PANEL_SCENE
# We use this variable, so that the scene can be overriden with a custom one
export var list_card_object_scene = _LIST_CARD_OBJECT_SCENE
# We use this variable, so that the scene can be overriden with a custom one
export var grid_card_object_scene = _GRID_CARD_OBJECT_SCENE
# These are passed to the rich_text_labels used in the card list
# To use as part of the card info.
export(Array, RichTextEffect) var custom_rich_text_effects := []

onready var _available_cards := $VBC/HBC/MC/AvailableCards/ScrollContainer/CardList
onready var _card_grid := $VBC/HBC/MC/AvailableCards/ScrollContainer/CardGrid
onready var _filter_line := $VBC/HBC/MC/AvailableCards/HBC/FilterLine
onready var _filter_buttons := $VBC/HBC/MC/AvailableCards/CC/ButtonFilters
onready var _card_count := $VBC/HBC/MC/AvailableCards/HBC/CardCount
onready var _card_headers := $VBC/HBC/MC/AvailableCards/CardListHeaders
onready var _card_name_header := $VBC/HBC/MC/AvailableCards/CardListHeaders/Name
onready var _card_type_header := $VBC/HBC/MC/AvailableCards/CardListHeaders/Type
onready var _show_all_button := $VBC/HBC/MC/AvailableCards/CC/ButtonFilters/ShowAll

func _ready() -> void:
	# This signal returns the load buttons' popup menu choice.
	populate_available_cards()
	# warning-ignore:return_value_discarded
	_filter_line.connect("filters_changed", self, "_apply_filters")
	prepate_filter_buttons()
	cfc.game_settings['deckbuilder_gridstyle'] =\
			cfc.game_settings.get('deckbuilder_gridstyle', true)
	$VBC/HBC/MC/AvailableCards/Settings/GridViewStyle.pressed =\
			cfc.game_settings.deckbuilder_gridstyle

	if cfc.game_settings.deckbuilder_gridstyle:
		var load_start_time = OS.get_ticks_msec()
		prepare_card_grid()
		var load_end_time = OS.get_ticks_msec()
		if OS.has_feature("debug") and not cfc.is_testing:
			print_debug("DEBUG INFO:CardViewer:Card Grid instance time = %sms" % [str(load_end_time - load_start_time)])
	_show_all_button.icon = CFUtils.convert_texture_to_image(
			"res://src/core/CardViewer/open-book.png")


## Prepares the filter buttons based on the unique values in cards.
func prepate_filter_buttons() -> void:
	var total_unique_values := 0
	for button_property in filter_button_properties:
		var unique_values := CFUtils.get_unique_values(button_property)
		total_unique_values += unique_values.size()
		# We want to avoid exceeding 8 buttons
		if total_unique_values <= 8:
			for value in CFUtils.get_unique_values(button_property):
				# Excluded types, don't have a filter button
				if value in CardConfig.TYPES_TO_HIDE_IN_CARDVIEWER:
					continue
				var filter_button = _FILTER_BUTTON_SCENE.instance()
				filter_button.setup(button_property, value)
				filter_button.connect("pressed", self, "_on_filter_button_pressed")
				filter_button.connect("right_pressed", self, "_on_filter_button_right_pressed", [filter_button])
				_filter_buttons.add_child(filter_button)
		# warning-ignore:return_value_discarded
		_show_all_button.connect("pressed", self, "_on_ShowAll_button_pressed")


func _process(_delta: float) -> void:
	# We keep updating the columns based on the card size
	_card_grid.columns = int(
			$"VBC/HBC/MC/AvailableCards/ScrollContainer".rect_size.x
			/ (CFConst.CARD_SIZE.x * CFConst.THUMBNAIL_SCALE * cfc.curr_scale))

# Populates the list of available cards, with all defined cards in the game
func populate_available_cards() -> void:
	var counter := 0
	for card_def in cfc.card_definitions:
		# This special meta property prevents cards from being used
		# in deckbuilding. Useful for token cards.
		if cfc.card_definitions[card_def].get(CardConfig.BOOL_PROPERTY_TO_HIDE_IN_CARDVIEWER)\
				or cfc.card_definitions[card_def].get(CardConfig.SCENE_PROPERTY)\
				in CardConfig.TYPES_TO_HIDE_IN_CARDVIEWER:
			continue
		var list_card_object = list_card_object_scene.instance()
		list_card_object.card_viewer = self
		_available_cards.add_child(list_card_object)
		list_card_object.setup(card_def)
		counter += 1
	_card_count.text = "Total: " + str(counter)



# Slowly loads all cards in to the grid
# We use a delay function between each card, to avoid freezing the game
# while instancing all the nodes
func prepare_card_grid(is_staggered:= false) -> void:
	for card_object in _available_cards.get_children():
		card_object.setup_grid_card_object()
		# This prevents the game from hanging while populating the grid
		# useful when the player populates the grid through the buttont
		# but during game start, it's better to populate it in one-go
		if is_staggered:
			yield(get_tree().create_timer(0.01), "timeout")

# Extend this class and call this function, when your game has a value field
# Which is suposed to be autogenerated in some fashion.
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func generate_value(property: String, card_properties: Dictionary):
	return('Autogenerated')

# evaluates all cards in available_cards against each filter returned by the
# FilterLine. Cards that don't match, are set invisible.
func _apply_filters(active_filters: Array) -> void:
	var counter := 0
	var total_count := 0
	for card_object in _available_cards.get_children():
		var set_visible = true
		for filter in active_filters:
			if not filter.assess_card_object(card_object):
				set_visible = false
		for property in filter_button_properties:
			var active_button_values = []
			for button in _filter_buttons.get_children():
				if button as CVFilterButton\
						and button.pressed\
						and button.property == property:
					active_button_values.append(button.value)
			if not card_object.card_properties.get(property):
				set_visible = false
			elif not card_object.card_properties[property]\
					in active_button_values:
				set_visible = false
		if not _check_custom_filters(card_object):
			set_visible = false
		card_object.set_visibility(set_visible)
		total_count += 1
		if set_visible:
			counter += 1
	if counter == total_count:
		_card_count.text = "Total: " + str(counter)
	else:
		_card_count.text = "Filtered: " + str(counter)


# functions to override in order to put in custom filters checks
func _check_custom_filters(_card_object: CVListCardObject) -> bool:
	return(true)


# Simply calls _apply_filters()
func _on_ShowAll_button_pressed() -> void:
	for button in _filter_buttons.get_children():
		if button as CVFilterButton\
				and not button.pressed:
			button.pressed = true
	_apply_filters(_filter_line.get_active_filters())

# Simply calls _apply_filters()
func _on_filter_button_pressed() -> void:
	_apply_filters(_filter_line.get_active_filters())

# Simply calls _apply_filters()
func _on_filter_button_right_pressed(filter_button: CVFilterButton) -> void:
	for button in _filter_buttons.get_children():
		if button as CVFilterButton\
				and button.pressed\
				and button != filter_button:
			button.pressed = false
	_apply_filters(_filter_line.get_active_filters())


# Clears all card filters
func _on_ClearFilters_pressed() -> void:
	_filter_line.text = ''
	_apply_filters(_filter_line.get_active_filters())

# When the grid view is switched, we instance all cards available in the game
# and put them in the grid.
func _on_GridViewStyle_toggled(button_pressed: bool) -> void:
	_available_cards.visible = !button_pressed
	$"VBC/HBC/MC/AvailableCards/CardListHeaders".visible = !button_pressed
	cfc.set_setting('deckbuilder_gridstyle',button_pressed)
	_card_grid.visible = button_pressed
	if button_pressed:
		prepare_card_grid(true)
