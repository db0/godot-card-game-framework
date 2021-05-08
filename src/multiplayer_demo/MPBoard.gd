# Code for a sample Multiplayerplayspace, you're expected to provide your own ;)
extends Board

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	counters = $Counters
	cfc.map_node(self)
	# We use the below while to wait until all the nodes we need have been mapped
	# "hand" should be one of them.
	# We're assigning our positions programmatically,
	# instead of defining them on the scene.
	# This way any they will work with any size of viewport in a game.
	# Discard pile goes bottom right
	$FancyMovementToggle.pressed = cfc.game_settings.fancy_movement
	$OvalHandToggle.pressed = cfc.game_settings.hand_use_oval_shape
	$ScalingFocusOptions.selected = cfc.game_settings.focus_style
	$Debug.pressed = cfc._debug
	# Fill up the deck for demo purposes
	if not cfc.ut:
		cfc.game_rng_seed = CFUtils.generate_random_seed()
		$SeedLabel.text = "Game Seed is: " + cfc.game_rng_seed
	# warning-ignore:return_value_discarded
	load_multiplayer_cards()



# Loads a sample set of cards to use for testing
func load_multiplayer_cards() -> void:

	var mp_card_array := []
	# We start from index 1, because the nakama server code running on lua
	# starts from 1 as well
	var card_index := 0
	if not cfc.multiplayer_match: return
	for card_entry in cfc.multiplayer_match.card_states:
		var new_card = cfc.instance_card(card_entry.card_name)
		mp_card_array.append(new_card)
		cfc.multiplayer_match.register_card(card_index, new_card)
		card_index += 1
	var payload := {"cards": {}}
	for card in mp_card_array:
		$Deck.add_child(card)
		#card.set_is_faceup(false,true)
		card._determine_idle_state()
		var card_mp_id = cfc.multiplayer_match.get_card_id(card)
		cfc.multiplayer_match.update_card_state(card,'container','deck')
		cfc.multiplayer_match.update_card_state(card,'position', card.position)
		payload.cards[card_mp_id] = cfc.multiplayer_match.get_card_state(card)
	cfc.multiplayer_match.nakama_client.socket.send_match_state_async(
			cfc.multiplayer_match.match_id,
			NWConst.OpCodes.cards_updated,
			JSON.print(payload))


# This function is to avoid relating the logic in the card objects
# to a node which might not be there in another game
# You can remove this function and the FancyMovementToggle button
# without issues
func _on_FancyMovementToggle_toggled(_button_pressed) -> void:
#	cfc.game_settings.fancy_movement = $FancyMovementToggle.pressed
	cfc.set_setting('fancy_movement', $FancyMovementToggle.pressed)


func _on_OvalHandToggle_toggled(_button_pressed: bool) -> void:
	cfc.set_setting("hand_use_oval_shape", $OvalHandToggle.pressed)
	for c in cfc.NMAP.hand.get_all_cards():
		c.reorganize_self()


# Reshuffles all Card objects created back into the deck
func _on_ReshuffleAllDeck_pressed() -> void:
	reshuffle_all_in_pile(cfc.NMAP.deck)


func _on_ReshuffleAllDiscard_pressed() -> void:
	reshuffle_all_in_pile(cfc.NMAP.discard)

func reshuffle_all_in_pile(pile = cfc.NMAP.deck):
	for c in get_tree().get_nodes_in_group("cards"):
		if c.get_parent() != pile:
			c.move_to(pile)
			yield(get_tree().create_timer(0.1), "timeout")
	# Last card in, is the top card of the pile
	var last_card : Card = pile.get_top_card()
	if last_card._tween.is_active():
		yield(last_card._tween, "tween_all_completed")
	yield(get_tree().create_timer(0.2), "timeout")
	pile.shuffle_cards()


# Button to change focus mode
func _on_ScalingFocusOptions_item_selected(index) -> void:
	cfc.set_setting('focus_style', index)


# Button to make all cards act as attachments
func _on_EnableAttach_toggled(button_pressed: bool) -> void:
	for c in get_tree().get_nodes_in_group("cards"):
		c.is_attachment = button_pressed


func _on_Debug_toggled(button_pressed: bool) -> void:
	cfc._debug = button_pressed


func _on_DeckBuilder_pressed() -> void:
	cfc.game_paused = true
	$DeckBuilderPopup.popup_centered_minsize()

func _on_Multiplayer_pressed() -> void:
	cfc.game_paused = true
	$MultiplayerPopup.popup_centered_minsize()

func _on_popup_hide() -> void:
	cfc.game_paused = false

