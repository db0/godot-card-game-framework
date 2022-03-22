# This class is not instanced via its name. 
# Rather it is instanced using its path from cfc
# This allows a game to extend it by extending this class
# and then replacing the path in CFConst.PATH_OVERRIDABLE_UTILS 
# with the location of their extended script.
class_name OVUtils
extends Reference

const _CARD_SELECT_SCENE_FILE = CFConst.PATH_CORE + "SelectionWindow.tscn"
const _CARD_SELECT_SCENE = preload(_CARD_SELECT_SCENE_FILE)

# Populates the info panels under the card, when it is shown in the
# viewport focus or deckbuilder
func populate_info_panels(card: Card, focus_info: DetailPanels) -> void:
	focus_info.hide_all_info()
	var card_illustration = card.get_property("_illustration")
	if card_illustration:
		focus_info.show_illustration("Illustration by: " + card_illustration)
	else:
		focus_info.hide_illustration()
	for tag in card.get_property("Tags"):
		if CardConfig.EXPLANATIONS.has(tag):
			focus_info.add_info(tag, CardConfig.EXPLANATIONS[tag])
	var card_keywords = card.get_property("_keywords")
	if card_keywords:
		for keyword in card_keywords:
			if CardConfig.EXPLANATIONS.has(keyword):
				focus_info.add_info(keyword, CardConfig.EXPLANATIONS[keyword])

func get_subjects(_subject_request, _stored_integer : int = 0) -> Array:
	return([])

func select_card(
		card_list: Array, 
		selection_count: int, 
		selection_type: String,
		selection_optional: bool,
		parent_node,
		card_select_scene = _CARD_SELECT_SCENE):
	if parent_node == cfc.NMAP.get("board"):
		cfc.game_paused = true
	var selected_cards
	# This way we can override the card select scene with a custom one
	var selection = card_select_scene.instance()
	parent_node.add_child(selection)
	selection.call_deferred("initiate_selection", card_list,selection_count,selection_type,selection_optional)
	# We have to wait until the player has finished selecting their cards
	yield(selection,"confirmed")
	if selection.is_cancelled:
		selected_cards = false
	else:
		selected_cards = selection.selected_cards
	# Garbage cleanup
	selection.queue_free()
	if parent_node == cfc.NMAP.get("board"):
		cfc.game_paused = false
	return(selected_cards)

# Goes through the card pool of the game and checks each card against the provided list of filters
# Then returns all card names matching the filters.
func filter_card_pool(filters_list: Array, card_pool := _get_card_pool()) -> Array:
	var matching_card_defs := []
	for card_name in card_pool:
		var matching_def := true
		# Each filter should be a CardFilter class
		for filter in filters_list:
			if not filter.check_card(card_pool[card_name]):
				matching_def = false
				break
		if matching_def:
			matching_card_defs.append(card_name)
	return(matching_card_defs)


# Overridable function to return the card pool of the game
# Games might decide to change how this is used for their own purposes.
func _get_card_pool() -> Dictionary:
	return(cfc.card_definitions)
