class_name NWMultiplayerMatch
extends Reference

var card_states: Array
var card_node_map: Dictionary
var container_node_map: Dictionary
var nakama_client : CFNakamaClient
var match_id: String
var is_single_board: bool

func _init(cards: Array, _nakama_client: CFNakamaClient, _match_id: String, _is_single_board: bool) -> void:
	match_id = _match_id
	is_single_board = _is_single_board
	card_states = cards.duplicate(true)
	nakama_client = _nakama_client
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")

func register_card(index, card) -> void:
	card_node_map[card] = index

func register_container() -> void:
	nakama_client.socket.send_match_state_async(
			match_id,
			NWConst.OpCodes.register_containers,
			JSON.print(cfc.NMAP.keys()))

func get_container_id(container) -> int:
	# We have to add +1 to the index, to match the lua indexes which start from 1
	return(container_node_map[container])
	
func get_card_id(card) -> int:
	# We have to add +1 to the index, to match the lua indexes which start from 1
	return(card_node_map[card] + 1)
	
func get_card_node(card_index) -> Node:
	var found_node : Node = null
	for card_node in card_node_map:
		if card_node_map[card_node] == card_index:
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
	print_debug(container_node_map)
#	var card_id := 1
#	for card_entry in card_states:
#		var card: Card = get_card_node(card_id)
#		card_id += 1
#	print_debug(state)

