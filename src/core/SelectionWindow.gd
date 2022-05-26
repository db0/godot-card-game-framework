class_name SelectionWindow
extends AcceptDialog

signal selection_window_opened(selection_window, signal_name, details)
signal card_selected(selection_window, signal_name, details)

# The path to the GridCardObject scene.
const _GRID_CARD_OBJECT_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVGridCardObject.tscn"
const _GRID_CARD_OBJECT_SCENE = preload(_GRID_CARD_OBJECT_SCENE_FILE)
const _INFO_PANEL_SCENE_FILE = CFConst.PATH_CORE\
		+ "CardViewer/CVInfoPanel.tscn"
const _INFO_PANEL_SCENE = preload(_INFO_PANEL_SCENE_FILE)

export(PackedScene) var grid_card_object_scene := _GRID_CARD_OBJECT_SCENE
export(PackedScene) var info_panel_scene := _INFO_PANEL_SCENE

var selected_cards := []
var selection_count : int
var selection_type: String
var is_selection_optional: bool
var is_cancelled := false
var _card_dupe_map := {}

onready var _card_grid = $GridContainer
onready var _tween = $Tween


func _ready() -> void:
	# For the counter signal, we "push" connect it instead from this node.
	# warning-ignore:return_value_discarded
	connect("selection_window_opened", cfc.signal_propagator, "_on_signal_received")
	# warning-ignore:return_value_discarded
	connect("card_selected", cfc.signal_propagator, "_on_signal_received")
	# warning-ignore:return_value_discarded
	connect("confirmed", self, "_on_card_selection_confirmed")

func _process(_delta):
	var current_count = selected_cards.size()
	# We disable the OK button, if the amount of cards to be
	# chosen do not match our expectations
	match selection_type:
		"min":
			if current_count < selection_count:
				get_ok().disabled = true
			else:
				get_ok().disabled = false
		"equal":
			if current_count != selection_count:
				get_ok().disabled = true
			else:
				get_ok().disabled = false
		"max":
			if current_count > selection_count:
				get_ok().disabled = true
			else:
				get_ok().disabled = false


# Populates the selection window with duplicates of the possible cards
# Then displays them in a popup for the player to select them.
func initiate_selection(
		card_array: Array,
		_selection_count := 0,
		_selection_type := 'min',
		_selection_optional := false) -> void:
	if OS.has_feature("debug") and not cfc.is_testing:
		print("DEBUG INFO:SelectionWindow: Initiated Selection")
	# We don't allow the player to close the popup with the close button
	# as that will not send the mandatory signal to unpause the game
	get_close_button().visible = false
	selection_count = _selection_count
	selection_type = _selection_type
	is_selection_optional = _selection_optional
	# If the selection is optional, we allow the player to cancel out
	# of the popup
	if is_selection_optional:
		var cancel_button := add_cancel("Cancel")
		# warning-ignore:return_value_discarded
		cancel_button.connect("pressed",self, "_on_cancel_pressed")
	# If the amount of cards available for the choice are below the requirements
	# We return that the selection was canceled
	elif card_array.size() < selection_count\
			and selection_type in ["equal", "min"]:
		selected_cards = []
		is_cancelled = true
		emit_signal("confirmed")
		return
	# If the selection count is 0 (e.g. reduced with an alterant)
	# And we're looking for max or equal amount of cards, we return cancelled.
	elif selection_count == 0\
			and selection_type in ["equal", "max"]:
		selected_cards = []
		is_cancelled = true
		emit_signal("confirmed")
		return
	# If the amount of cards available for the choice are exactly the requirements
	# And we're looking for equal or minimum amount
	# We immediately return what is there.
	elif card_array.size() == selection_count\
			and selection_type in ["equal", "min"]:
		selected_cards = card_array
		emit_signal("confirmed")
		return
	# When we have 0 cards to select from, we consider the selection cancelled
	elif card_array.size() == 0:
		is_cancelled = true
		emit_signal("confirmed")
		return
	match selection_type:
		"min":
			window_title = "Select at least " + str(selection_count) + " cards."
		"max":
			window_title = "Select at most " + str(selection_count) + " cards."
		"equal":
			window_title = "Select exactly " + str(selection_count) + " cards."
		"display":
			window_title = "Press OK to continue"
	for c in _card_grid.get_children():
		c.queue_free()
	# We use this to quickly store a copy of a card object to use to get
	# the card sizes for adjusting the size of the popup
	var card_sample: Card
	# for each card that the player needs to select amonst
	# we create a duplicate card inside a Card Grid object
	for card in card_array:
		var dupe_selection: Card
		if typeof(card) == TYPE_STRING:
			dupe_selection = cfc.instance_card(card)
		else:
			dupe_selection = card.duplicate(DUPLICATE_USE_INSTANCING)
			# This prevents the card from being scripted with the
			# signal propagator and other things going via groups
			dupe_selection.remove_from_group("cards")
			dupe_selection.canonical_name = card.canonical_name
			dupe_selection.properties = card.properties.duplicate()
		card_sample = dupe_selection
		var card_grid_obj = grid_card_object_scene.instance()
		_card_grid.add_child(card_grid_obj)
		# This is necessary setup for the card grid container
		card_grid_obj.preview_popup.focus_info.info_panel_scene = info_panel_scene
		card_grid_obj.preview_popup.focus_info.setup()
		card_grid_obj.setup(dupe_selection)
		_extra_dupe_ready(dupe_selection, card)
		_card_dupe_map[card] = dupe_selection
		# warning-ignore:return_value_discarded
		dupe_selection.set_is_faceup(true,true)
		dupe_selection.ensure_proper()
		# We connect each card grid's gui input into a call which will handle
		# The selections
		card_grid_obj.connect("gui_input", self, "on_selection_gui_input", [dupe_selection, card])
	# We don't want to show a popup longer than the cards. So the width is based on the lowest
	# between the grid columns or the amount of cards
	var shown_columns = min(_card_grid.columns, card_array.size())
	var card_size = CFConst.CARD_SIZE
	var thumbnail_scale = CFConst.THUMBNAIL_SCALE
	if card_sample as Card:
		card_size = card_sample.canonical_size
		thumbnail_scale = card_sample.thumbnail_scale
	var popup_size_x = (card_size.x * thumbnail_scale * shown_columns * cfc.curr_scale)\
			+ _card_grid.get("custom_constants/vseparation") * shown_columns
	# The height will be automatically adjusted based on the amount of cards
	rect_size = Vector2(popup_size_x,0)
	popup_centered_minsize()
	# Spawning all the duplicates is a bit heavy
	# So we delay showing the tween to avoid having it look choppy
	yield(get_tree().create_timer(0.2), "timeout")
	_tween.remove_all()
	# We do a nice alpha-modulate tween
	_tween.interpolate_property(self,'modulate:a',
			0, 1, 0.5,
			Tween.TRANS_SINE, Tween.EASE_IN)
	_tween.start()
	emit_signal(
			"selection_window_opened",
			self,
			"selection_window_opened",
			{"card_selection_options": _card_dupe_map.keys()}
	)
	if OS.has_feature("debug") and not cfc.is_testing:
		print("DEBUG INFO:SelectionWindow: Started Card Display with a %s card selection" % [_card_grid.get_child_count()])


# Overridable function for games to extend processing of dupe card
# after adding it to the scene
func _extra_dupe_ready(dupe_selection: Card, _card: Card) -> void:
	dupe_selection.targeting_arrow.visible = false


# The player can select the cards using a simple left-click.
func on_selection_gui_input(event: InputEvent, dupe_selection: Card, origin_card) -> void:
	if event is InputEventMouseButton\
			and event.is_pressed()\
			and event.get_button_index() == 1\
			and selection_type != 'display':
		# Each time a card is clicked, it's selected/unselected
		if origin_card in selected_cards:
			selected_cards.erase(origin_card)
			dupe_selection.highlight.set_highlight(false)
		else:
			selected_cards.append(origin_card)
			dupe_selection.highlight.set_highlight(true)
		# We want to avoid the player being able to select more cards than
		# the max, even if the OK button is disabled
		# So whenever they exceed the max, we unselect the first card in the array.
		if selection_type in ["equal", "max"]  and selected_cards.size() > selection_count:
			_card_dupe_map[selected_cards[0]].highlight.set_highlight(false)
			selected_cards.remove(0)


# Manually selects cards based on their index.
# Typically used for testing
# Returns an array with the Card object selected
func select_cards(indexes :Array = []) -> Array:
	var all_choices = _card_dupe_map.keys()
	for index in indexes:
		if index + 1 > all_choices.size():
			continue
		selected_cards.append(all_choices[index])
	emit_signal("confirmed")
	return(selected_cards)


func get_all_card_options() -> Array:
	return(_card_dupe_map.keys())

# Cancels out of the selection window
func _on_cancel_pressed() -> void:
	selected_cards.clear()
	is_cancelled = true
	# The signal is the same, but the calling method, should be checking the
	# is_cancelled bool.
	# This is to be able to yield to only one specific signal.
	emit_signal("confirmed")

func _on_card_selection_confirmed() -> void:
	if is_cancelled:
		return
	emit_signal(
			"card_selected",
			self,
			"card_selected",
			{"selected_cards": selected_cards}
	)
