class_name NWMultiplayerMatch
extends Reference

var card_states: Array
var nakama_client : CFNakamaClient
var match_id: String

func _init(cards: Array, _nakama_client: CFNakamaClient, _match_id: String) -> void:
	match_id = _match_id
	card_states = cards.duplicate(true)
	nakama_client = _nakama_client
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")

func get_card_node_mp_id(card_node) -> int:
	var ret_index := -1
	var seek_index := 0
	for c in card_states:
		if c.card_node == card_node:
			ret_index = seek_index
			break
		else:
			seek_index += 1
	return(ret_index)

func _on_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var state : Dictionary = JSON.parse(match_state.data).result	
	print_debug(state)

