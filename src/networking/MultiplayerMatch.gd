class_name NWMultiplayerMatch
extends Reference

signal received_mp_state

var card_states: Array
var card_node_map: Dictionary
var container_node_map: Dictionary
var nakama_client : CFNakamaClient
var match_id: String
# This holds all card state manipulations that happened in the past
# X seconds, where X is the `manipulation_spool` variable.
var manipulation_spool: Array
# To avoid overwhelming the Nakama server during massive manipulations
# we spool all requests coming in this amount of seconds and send them all
# as one sync request.
var spool_timer_delay := 1.15
# This timer starts when a request to send the card state to nakama arrives
# and when it expires, the state is sent.
var send_state_timer := Timer.new()



func _init(cards: Array, _nakama_client: CFNakamaClient, _match_id: String) -> void:
	match_id = _match_id
	card_states = cards.duplicate(true)
	nakama_client = _nakama_client
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")
	send_state_timer.connect("timeout", self, '_on_card_state_manipulated')
	send_state_timer.one_shot = true
	cfc.add_child(send_state_timer)

func register_card(index, card) -> void:
	card_node_map[card] = index
#	for sgn in cfc.SignalPropagator.known_card_signals:
#		card.connect(sgn, self, "_on_card_signal_received")
#	card.connect("state_manipulated", self, "_on_card_state_manipulated")

func register_container() -> void:
	var payload := {"containers": cfc.NMAP.keys()}
	nakama_client.socket.send_match_state_async(
			match_id,
			NWConst.OpCodes.register_containers,
			JSON.print(payload))
	for container in cfc.get_tree().get_nodes_in_group("card_containers"):
		container.connect("container_shuffled", self, "_on_container_shuffled")

func get_container_id(container) -> int:
	return(container_node_map[container])

func get_container_node(container_index) -> Node:
	var found_node : Node = null
	for container_node in container_node_map:
#		print_debug(card_node,card_node_map[card_node], card_index)
		if container_node_map[container_node] == container_index:
			found_node = container_node
	return(found_node)


func get_card_id(card) -> int:
	# We have to add +1 to the index, to match the lua indexes which start from 1
	return(card_node_map[card] + 1)

func get_card_node(card_index) -> Node:
	var found_node : Node = null
	for card_node in card_node_map:
#		print_debug(card_node,card_node_map[card_node], card_index)
		if card_node_map[card_node] + 1 == card_index:
			found_node = card_node
	return(found_node)

func update_card_state(card, key, value) -> void:
	card_states[card_node_map[card]][key] = value

func get_card_state(card) -> Dictionary:
	return(card_states[card_node_map[card]])

func _on_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var state : Dictionary = JSON.parse(match_state.data).result
	card_states = state.cards.duplicate(true)
	var shuffled_containers = state.shuffled_containers.duplicate(true)
	var cont_index := 1
	for container in state.containers:
		container_node_map[cfc.NMAP[container]] = cont_index
		cont_index += 1
	var card_id := 1
	for card_entry in card_states:
		var card: Card = get_card_node(card_id)
		sync_card(card, card_entry)
		card_id += 1
	# If we received the note that a container has been shuffled
	# we perform the shuffle animation, without actually shuffling the cards.
	# The individual index of cards will be received from the data as well.
	for container_id in shuffled_containers:
		var container := get_container_node(container_id)
		while container.is_animation_ongoing():
			yield(container.get_tree().create_timer(0.1), "timeout")
		if container.is_in_group("hands"):
			container.shuffle_cards(true)
		elif container.is_in_group("piles"):
			container.shuffle_cards(true, true)
	emit_signal("received_mp_state")
#	print_debug(state)

func sync_card(card: Card, card_entry: Dictionary) -> void:
#	print_debug(card)
	# In case the card is currently in progress of being moved
	# wa want to try again later, if the card state is still wrong
	if card._tween and card._tween.is_active():
		return
#	print_debug(card.current_manipulation == Card.StateManipulation.LOCAL)
	if card.get_parent() == cfc.NMAP.board:
		print_debug(card_entry.board_grid_slot)
	if card.current_manipulation == Card.StateManipulation.LOCAL:
		return
	if _is_container_still_manipulated(card):
		return
	# We do positioning manipulation changes only if the card state received
	# contains a Card Container reference ID.
	# (otherwise it means the card is not really active in the game yet)
	if card_entry.get('container'):
		card.set_current_manipulation(Card.StateManipulation.REMOTE)
		var card_container = get_container_node(card_entry.container)
	#	print_debug(card_container)
		var card_position = Vector2(card_entry.pos_x, card_entry.pos_y)
		var board_grid_slot  = null
		var board_grid_details = card_entry.get("board_grid_slot")
		if board_grid_details:
			var board_grid = cfc.NMAP.board.get_grid(board_grid_details[0])
			board_grid_slot = board_grid.get_slot(board_grid_details[1])
		if card_container != card.get_parent():
			if card_container == cfc.NMAP.board:
				if board_grid_slot:
					card.move_to(card_container, -1, board_grid_slot)
				else:
					card.move_to(card_container, -1, card_position)
			else:
				card.move_to(card_container, card_entry.node_index)
		elif card_container == cfc.NMAP.board:
			if board_grid_slot and board_grid_slot != card._placement_slot:
				card.move_to(card_container, -1, board_grid_slot)
			elif not board_grid_slot and card_position != card.position:
				print( card_position, board_grid_slot, card.position,card._placement_slot)
#				print_debug(card.current_manipulation,card_position,card.position )
				card.position = card_position
	#			card._add_tween_position(card.position, card_position, 0.15,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		elif card_entry.node_index != card.get_my_card_index():
#			print_debug(card_container.name,card_entry.node_index,card.get_parent().name,card.get_my_card_index())
#			print_debug(card_entry.node_index,card.get_my_card_index())
			card.get_parent().move_child(
					card,
					card.get_parent().translate_card_index_to_node_index(
						card_entry.node_index))
		if card_entry.has('rotation')\
				and card.card_rotation != card_entry['rotation']:
				card.card_rotation = card_entry['rotation']
		if card_entry.has('is_faceup')\
				and card.is_faceup != card_entry['is_faceup']:
				card.is_faceup = card_entry['is_faceup']
		for card_property in card_entry["properties"]:
			var remote_value = card_entry["properties"][card_property]
			if card.properties[card_property] != remote_value:
				card.modify_property(card_property, remote_value)
		for token_name in card_entry.get("tokens", {}):
			var remote_value = card_entry["tokens"][token_name]
			var token: Token = card.tokens.get_token(token_name)
			if token and token.get_unaltered_count() != remote_value:
				card.tokens.mod_token(token_name, remote_value, true)
		card.set_current_manipulation(Card.StateManipulation.NONE)
#	print_debug(card_entry)


func _on_card_state_manipulated():
	var payload := { "cards": {}}
	# We add a wait to allow any tweens which are about to start, to start
	var card_indexes_updated := false
	var entries_to_unspool: Array
	while manipulation_spool.size():
		var entry: SpooledEntry = manipulation_spool.pop_back()
		# If any of the manipulations moves cards around the board
		# we need to resend the positional state of all cards
		# due to indexes shifting as cards get added/(re)moved from containers.
		if not card_indexes_updated and entry.is_index_manipulation():
			card_indexes_updated = true
			for card_obj in cfc.get_tree().get_nodes_in_group("cards"):
				var card: Card = card_obj
				var card_id := get_card_id(card)
				if not payload["cards"].has(card_id):
					payload["cards"][card_id] = {}
				var positional_payload := SpooledEntry.get_positional_payload(
						card, container_node_map)
				payload["cards"][card_id]["pos_x"] = positional_payload["pos_x"]
				payload["cards"][card_id]["pos_y"] = positional_payload["pos_y"]
				payload['cards'][card_id]["board_grid_slot"] = positional_payload["board_grid_slot"]
				payload['cards'][card_id]["node_index"] = positional_payload["node_index"]
				payload['cards'][card_id]["container"] = positional_payload["container"]
		var card_id := get_card_id(entry.card)
		if not payload["cards"].has(card_id):
			payload["cards"][card_id] = {}
		payload['cards'][card_id] = entry.get_payload(
				payload["cards"][card_id], container_node_map)
		if not entry in entries_to_unspool:
			entries_to_unspool.append(entry)
		if manipulation_spool.size() == 0:
			print_debug(payload)
			# We want to wait until the state has been updated remotely,
			# before unlocking the card for remote manipulations
			yield(nakama_client.socket.send_match_state_async(
					match_id,
					NWConst.OpCodes.cards_updated,
					JSON.print(payload)), "completed")
			for e in entries_to_unspool:
				e.unspool()
			print_debug('unspooled all')
			# if we've sent the call to sync match state
			# we ensure we break out of the spool parsing loop
			# even if an entry was added in while waiting for the async
			# yield to return.
			break
#	print_debug(manipulation_spool.size())


func _on_container_shuffled(container: CardContainer) -> void:
	print_debug("shuffle signal received")
	var payload := {"container_id": get_container_id(container)}
	for c in container.get_all_cards():
		add_manipulation_to_spool(c, "card_index_changed")
	yield(nakama_client.socket.send_match_state_async(
			match_id,
			NWConst.OpCodes.container_shuffled,
			JSON.print(payload)), "completed")


func add_manipulation_to_spool(card: Card, manipulation_type: String) -> void:
	var manipulation_entry : SpooledEntry
	for entry in manipulation_spool:
		if entry.card == card:
			manipulation_entry = entry
			manipulation_entry.add_manipulation(manipulation_type)
			break
	if not manipulation_entry:
		manipulation_entry = SpooledEntry.new(card, manipulation_type)
		manipulation_spool.append(manipulation_entry)
	if send_state_timer.is_stopped():
		send_state_timer.start(spool_timer_delay)

func _is_container_still_manipulated(card) -> bool:
	for entry in manipulation_spool:
		# We check if the parent of the checked card
		# is the parent of any card in the manipulation_spool
		if entry.is_container_manipulated(card):
			return(true)
	return(false)
