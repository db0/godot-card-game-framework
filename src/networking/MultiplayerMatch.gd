class_name NWMultiplayerMatch
extends Reference

var card_states: Array
var card_node_map: Dictionary
var nakama_client : CFNakamaClient
var match_id: String

func _init(cards: Array, _nakama_client: CFNakamaClient, _match_id: String) -> void:
	match_id = _match_id
	card_states = cards.duplicate(true)
	nakama_client = _nakama_client
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")

func register_card(index, card) -> void:
	card_node_map[card] = index

func _on_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var state : Dictionary = JSON.parse(match_state.data).result	
	print_debug(state)

