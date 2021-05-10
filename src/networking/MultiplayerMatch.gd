class_name NWMultiplayerMatch
extends Reference

signal received_mp_state

var card_states: Array
var card_node_map: Dictionary
var container_node_map: Dictionary
var nakama_client : CFNakamaClient
var match_id: String


func _init(cards: Array, _nakama_client: CFNakamaClient, _match_id: String) -> void:
	match_id = _match_id
	card_states = cards.duplicate(true)
	nakama_client = _nakama_client
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")

func register_card(index, card) -> void:
	card_node_map[card] = index
	card.connect("state_manipulated", self, "_on_card_state_manipulated")

func register_container() -> void:
	var payload := {"containers": cfc.NMAP.keys()}
	nakama_client.socket.send_match_state_async(
			match_id,
			NWConst.OpCodes.register_containers,
			JSON.print(payload))

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
	var cont_index := 1
	for container in state.containers:
		container_node_map[cfc.NMAP[container]] = cont_index
		cont_index += 1
	var card_id := 1
	for card_entry in card_states:
		var card: Card = get_card_node(card_id)
		sync_card(card, card_entry)
		card_id += 1
	emit_signal("received_mp_state")
#	print_debug(state)

func sync_card(card: Card, card_entry: Dictionary) -> void:
#	print_debug(card)
	# In case the card is currently in progress of being moved
	# wa want to try again later, if the card state is still wrong
	if card._tween and card._tween.is_active():
		return
	if card.current_manipulation == Card.StateManipulation.LOCAL:
		return
	if card_entry.get('container'):
		var card_container = get_container_node(card_entry.container)
	#	print_debug(card_container)
		var card_position = Vector2(card_entry.pos_x, card_entry.pos_y)
		var board_grid_slot  = null
		var board_grid_details = card_entry.get("board_grid_slot")
		if board_grid_details:
			var board_grid = cfc.NMAP.board.get_grid(board_grid_details[0])
			board_grid_slot = board_grid.get_slot(board_grid_details[1])			
		if card_container != card.get_parent():
			card.set_current_manipulation(Card.StateManipulation.REMOTE)
			if card_container == cfc.NMAP.board:
				if board_grid_slot:
					card.move_to(card_container, -1, board_grid_slot)
				else:
					card.move_to(card_container, -1, card_position)
			else:
				card.move_to(card_container, card_entry.node_index)
			card.set_current_manipulation(Card.StateManipulation.NONE)
		# WARNING: Adjusting the index doesn't work too well because I would have the send
		# index updates for a whole container woth of cards, 
		# whenever any card is moved outof/into it 
		# as everything else will be shifted automatically to accomodate.
#		elif card_entry.node_index != card.get_my_card_index():
#			print(card_container.name,card_entry.node_index,card.get_parent().name,card.get_my_card_index())
#			card.set_current_manipulation(Card.StateManipulation.REMOTE)
#			card.get_parent().move_child(card, card.get_parent().translate_card_index_to_node_index(card_entry.node_index))
#			card.set_current_manipulation(Card.StateManipulation.NONE)
		elif card_container == cfc.NMAP.board:
			if board_grid_slot and board_grid_slot != card._placement_slot:
				card.set_current_manipulation(Card.StateManipulation.REMOTE)
				card.move_to(card_container, -1, board_grid_slot)
				card.set_current_manipulation(Card.StateManipulation.NONE)
			elif not board_grid_slot and card_position != card.position:
				print( card_position, board_grid_slot, card.position,card._placement_slot)
#				print_debug(card.current_manipulation,card_position,card.position )
				card.set_current_manipulation(Card.StateManipulation.REMOTE)
				card.position = card_position
	#			card._add_tween_position(card.position, card_position, 0.15,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				card.set_current_manipulation(Card.StateManipulation.NONE)
#	print_debug(card_entry)



func _on_card_state_manipulated(cards):
	if typeof(cards) != TYPE_ARRAY:
		cards = [cards]
	var payload := { "cards": {}}
	for card in cards:
		var previous_state = card_states[card_node_map[card]]
		var card_id := get_card_id(card)
		# We add a wait to allow any tweens which are about to start, to start
		yield(card.get_tree().create_timer(0.1), "timeout")
	#	print_debug(card._tween.is_active(), card._tween.get_runtime())
		# We want to send the absolute final state of the card 
		# So we need to wait for all the tweens to finish first
	#	var loops = 0
	#	while card._tween.is_active():
	#		yield(card._tween, "tween_all_completed")
	#		# We add a wait before the next loop
	#		# to allow the next tween to start, in case there's more than one
	#		# running in a row
	#		yield(card.get_tree().create_timer(0.1), "timeout")
	#		loops += 1
	#		# We keep this as a safety to avoid getting stuck somehow
	#		if loops > 5: break
		payload["cards"][card_id] = {
			"card_name": card.canonical_name,
			"owner": previous_state['owner'],
			"pos_x": card.position.x,
			"pos_y": card.position.y,
		}
	#	print_debug(payload)
		var card_parent = discover_card_container(card)
		if card_parent:
			payload['cards'][card_id]["container"] =\
					get_container_id(discover_card_container(card))
			var board_grid_slot = null
			if card._placement_slot:
				board_grid_slot = [
						card._placement_slot.get_grid_name(),
						card._placement_slot.get_index()
				]
			payload['cards'][card_id]["board_grid_slot"] = board_grid_slot
			payload['cards'][card_id]["node_index"] =\
					card.get_my_card_index()


		# We want to wait until the state has been updated remotely, 
		# before unlocking the card for remote manipulations
	yield(nakama_client.socket.send_match_state_async(
			match_id,
			NWConst.OpCodes.cards_updated,
			JSON.print(payload)), "completed")
	for card in cards:			
		card.set_current_manipulation(Card.StateManipulation.NONE)

func discover_card_container(card: Card) -> Node:
	var card_parent = card.get_parent()
	if card_parent and is_instance_valid(card_parent):
		if "CardPopUpSlot" in card_parent.name:
			card_parent = card_parent.get_parent().get_parent().get_parent()
	else:
		card_parent = null
	return(card_parent)
