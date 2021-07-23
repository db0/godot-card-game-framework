# A Deckbuilder which allows players to construct, save and load decks
# to use in the game
class_name DeckBuilder
extends CardViewer

const _DECK_CARD_OBJECT_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/DeckBuilder/DBDeckCardObject.tscn"
const _DECK_CARD_OBJECT_SCENE = preload(_DECK_CARD_OBJECT_SCENE_FILE)
# The path to the CategoryScene scene.
const _DECK_CATEGORY_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/DeckBuilder/CategoryContainer.tscn"
const _DECK_CATEGORY_SCENE = preload(_DECK_CATEGORY_SCENE_FILE)
const _DECK_SUMMARIES_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/DeckBuilder/DBDeckSummaries.tscn"
const _DECK_SUMMARIES_SCENE = preload(_DECK_SUMMARIES_SCENE_FILE)

# Contains a link to the random deck name generator reference
export(Script) var deck_name_randomizer
# Controls how often an random adverb will
# not appear in front of the adjective. The higher the number, the less likely
# to get an adverb
# Adverbs will not appear if adjectives did not.
export var random_adverb_miss := 10
# Controls how often an random adjective will
# not appear in front of the noun. The higher the number, the less likely
# to get an adjective
export var random_adjective_miss := 1.1
# Controls how often an random append will
# not appear in front of the deck name.
# The higher the number, the less likely to get an append
export var random_append_miss := 2
# Controls how often a second noun will appear in the name.
# The higher the number, the less likely a second nount to appear
export var second_noun_miss := 3
# The maximum amount of each card allowed in a deck.
# Individual cards can modify  this
export var max_quantity: int = 3
# The minimum amount cards required in a deck
export var deck_minimum: int = 52
# The maximum amount cards required in a deck
export var deck_maximum: int = 60
# We use this variable, so that the scene can be overriden with a custom one
export var deck_card_object_scene = _DECK_CARD_OBJECT_SCENE
# We use this variable, so that the scene can be overriden with a custom one
export var deck_summary_scene = _DECK_SUMMARIES_SCENE

# This var will hold a pointer to the deck summaries scene.
var deck_summaries

onready var _deck_cards := $VBC/HBC/DeckMC/CurrentDeck/ScrollContainer/CardsInDeck
onready var _deck_name := $VBC/HBC/DeckMC/CurrentDeck/DeckNameEdit
onready var _load_button := $VBC/HBC/DeckMC/CurrentDeck/Buttons/Load
onready var _notice := $VBC/HBC/DeckMC/CurrentDeck/HBoxContainer/NoticeLabel
onready var _save_button := $VBC/HBC/DeckMC/CurrentDeck/Buttons/Save
onready var _reset_button := $VBC/HBC/DeckMC/CurrentDeck/Buttons/Reset
onready var _delete_button := $VBC/HBC/DeckMC/CurrentDeck/Buttons/Delete
onready var _randomize_name_button := $VBC/HBC/DeckMC/CurrentDeck/HBoxContainer/RandomizeName

func _ready() -> void:
	deck_summaries = deck_summary_scene.instance()
	$VBC/HBC/DeckMC/CurrentDeck/DeckDetails.add_child(deck_summaries)
	deck_summaries.setup()
	# warning-ignore:return_value_discarded
	_load_button.connect("deck_loaded", self,"_on_deck_loaded")
	_deck_name.text = generate_random_deck_name()
	# warning-ignore:return_value_discarded
	_save_button.connect("pressed",self,"_on_Save_pressed")
	# warning-ignore:return_value_discarded
	_reset_button.connect("pressed",self,"_on_Reset_pressed")
	# warning-ignore:return_value_discarded
	_delete_button.connect("pressed",self,"_on_Delete_pressed")
	# warning-ignore:return_value_discarded
	_randomize_name_button.connect("pressed",self,"_on_RandomizeName_pressed")


func _process(_delta: float) -> void:
	# We keep updating the card count label with the amount of cards in the deck
	var card_count = 0
	for category in _deck_cards.get_children():
		for card_object in category.get_node("CategoryCards").get_children():
			card_count += card_object.quantity
	deck_summaries.deck_min_label.text = str(card_count) + ' Cards'
	if deck_minimum and deck_maximum:
		deck_summaries.deck_min_label.text += ' (min ' + str(deck_minimum)\
				+ ', max ' + str(deck_maximum) + ')'
	elif deck_minimum:
		deck_summaries.deck_min_label.text += ' (min ' + str(deck_minimum) + ')'
	elif deck_maximum:
		deck_summaries.deck_min_label.text += ' (max ' + str(deck_maximum) + ')'
	# We paint the font red if the deck is invalid
	if (deck_minimum and card_count < deck_minimum)\
			or (deck_maximum and card_count > deck_maximum):
		deck_summaries.deck_min_label.modulate = Color(1,0,0)
	else:
		deck_summaries.deck_min_label.modulate = Color(1,1,1)

# Populates the list of available cards, with all defined cards in the game
func populate_available_cards() -> void:
	.populate_available_cards()
	for list_card_object in _available_cards.get_children():
		list_card_object.max_allowed = max_quantity
		list_card_object.setup_max_quantity()
		list_card_object.set_quantity(0)		


# Adds a card to the deck.
# Ensures that the card is put under its own category for readability
func add_new_card(card_name, category, value) -> DBDeckCardObject:
	var category_container
	# If the category does not exist, we have to instance it.
	# Categories are using the same card field as the card templates.
	if not _deck_cards.has_node(category):
		category_container = _DECK_CATEGORY_SCENE.instance()
		category_container.name = category
		_deck_cards.add_child(category_container)
		category_container.get_node("CategoryLabel").text = category
	else:
		category_container = _deck_cards.get_node(category)
	var category_cards_node = category_container.get_node("CategoryCards")
	var deck_card_object = deck_card_object_scene.instance()
	category_cards_node.add_child(deck_card_object)
	deck_card_object.setup(card_name, value)
	return(deck_card_object)

# Triggered when a deck has been chosen from the Load menu
# Populates the Current Deck Details with the contents of the chosen deck
# as they were stored to disk.
func _on_deck_loaded(deck) -> void:
	# We need to zero all available cards,
	# otherwise previous selections will not be wiped if they're not in the deck
	for list_card_object in _available_cards.get_children():
		list_card_object.quantity = 0
	_deck_name.text = deck.name
	for card_name in deck.cards:
		# Our Current Deck quantities are always populated via the
		# ListCardObjects. So we need to modify those in order to update the
		# deck itself and connect the objects correctly.
		for list_card_object in _available_cards.get_children():
			if list_card_object.card_name == card_name:
				list_card_object.quantity = deck.cards[card_name]
	_set_notice("Deck loaded")


# Triggered when the Save button is pressed.
# Stores the deck in JSON format to the folder defined in CFConst.DECKS_PATH
func _on_Save_pressed() -> void:
	var cards_count = 0
	var deck_dictionary := {
		"name": _deck_name.text,
		"cards": {},
	}
	for category in _deck_cards.get_children():
		for card_object in category.get_node("CategoryCards").get_children():
			deck_dictionary.cards[card_object.card_name] = card_object.quantity
			cards_count += card_object.quantity
	deck_dictionary["total"] = cards_count
	var dir = Directory.new()
	if not dir.dir_exists(CFConst.DECKS_PATH):
		dir.make_dir(CFConst.DECKS_PATH)
	var file = File.new()
	file.open(CFConst.DECKS_PATH + _deck_name.text + '.json', File.WRITE)
	file.store_string(JSON.print(deck_dictionary, '\t'))
	file.close()
	_set_notice("Deck saved")


# Deletes the currently named deck, but doesn't clear the list
# This way the user can re-save the deck, if they deleted by mistake
func _on_Delete_pressed() -> void:
	var dir = Directory.new()
	if dir.dir_exists(CFConst.DECKS_PATH):
		var op_result = dir.remove(CFConst.DECKS_PATH + _deck_name.text + '.json')
		if op_result == OK:
			_set_notice("Deck deleted from disk. Current list not cleared")
		elif op_result == FAILED:
			_set_notice("Deck not found on disk", Color(1,1,0))
		elif op_result == ERR_FILE_NO_PERMISSION:
			_set_notice("Permission Denied", Color(1,0,0))


# Generates a random deck name using on the deck_name_randomizer
func generate_random_deck_name() -> String:
	cfc.game_rng.randomize()
	var name_randomizer = deck_name_randomizer.new()
	var deck_name := {}
	var rng: int = CFUtils.randi_range(0,
			name_randomizer.adjectives.size() * random_adjective_miss)
	if rng < name_randomizer.adjectives.size():
		deck_name["adjective"] = name_randomizer.adjectives[rng]
		rng = CFUtils.randi_range(0,
			name_randomizer.adverbs.size() * random_adverb_miss)
		if rng < name_randomizer.adverbs.size():
			deck_name["adverb"] = name_randomizer.adverbs[rng]
	rng = CFUtils.randi_range(0,name_randomizer.nouns.size() - 1)
	deck_name["noun"] = name_randomizer.nouns[rng]
	rng = CFUtils.randi_range(0,name_randomizer.nouns.size() - 1)
	var second_noun = name_randomizer.nouns[rng]
	if not CFUtils.randi_range(0,second_noun_miss)\
			and deck_name["noun"] != second_noun:
		deck_name["second_noun"] = second_noun
	rng = CFUtils.randi_range(0,name_randomizer.appends.size() * random_append_miss)
	if rng < name_randomizer.appends.size():
		deck_name["append"] = name_randomizer.appends[rng]
	var compiled_deck_name: PoolStringArray = []
	for part in ["adverb", "adjective", "noun", "second_noun", "append"]:
		if deck_name.get(part):
			compiled_deck_name.append(deck_name.get(part))
	return(compiled_deck_name.join(' ').strip_edges())

# Clears deck list
func _on_Reset_pressed() -> void:
	for card_object in _available_cards.get_children():
		card_object.quantity = 0
	_set_notice("Deck list reset")


# Ranzomizes deck name
func _on_RandomizeName_pressed() -> void:
	_deck_name.text = generate_random_deck_name()


# Shows a fading text to the user notifying them of recent action results.
func _set_notice(text: String, colour := Color(0,1,0)) -> void:
	var tween: Tween = _notice.get_node("Tween")
	_notice.text = text
	_notice.modulate.a = 1
	_notice.set("custom_colors/font_color",colour)
	# warning-ignore:return_value_discarded
	tween.remove_all()
	# warning-ignore:return_value_discarded
	tween.interpolate_property(_notice,'modulate:a',
			1, 0, 2, Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	tween.start()
