class_name NWPlayerLobbyObject
extends HBoxContainer

var user_id: String
var username: String
var match_maker
var _nakama_client: CFNakamaClient

onready var _player_name_label = $PlayerName
onready var _deck_loader = $DeckLoader
onready var _spectator_button = $Spectator
onready var _status_label = $Status
onready var _kick_button = $Kick

func setup(_username, _user_id, _match_maker, lobby_owner_id) -> void:
	username = _username
	if lobby_owner_id == _user_id:
		_player_name_label.text = username + ' (Host)'
	else:
		_player_name_label.text = username
	user_id = _user_id
	match_maker = _match_maker
	_nakama_client = match_maker.nakama_client
	if match_maker.user_id == _user_id:
		_status_label.visible = false
		_kick_button.visible = false
	else:
		_deck_loader.visible = false
		if not lobby_owner_id == match_maker.user_id:
			_kick_button.visible = false
			_spectator_button.visible = false

func set_status(deck, is_spectator) -> void:
	if _spectator_button.pressed != is_spectator:
		_spectator_button.pressed = is_spectator
		_deck_loader.visible = !is_spectator
	if is_spectator:
		if _status_label.text != "Spectator":
			_status_label.text = "Spectator"
	elif deck != null:
		if _status_label.text != deck.name + " (" + str(deck.total) + ")":
			_status_label.text = deck.name + " (" + str(deck.total) + ")"
	else:
		_status_label.text = "Not Ready"


func _on_DeckLoader_deck_loaded(deck) -> void:
	_deck_loader.text = deck.name + " (" + str(deck.total) + ")"
	var payload := {
		"deck": deck,
	}
	_nakama_client.socket.send_match_state_async(
			match_maker.joined_match_lobby.match_id,
			NWConst.OpCodes.deck_loaded,
			JSON.print(payload))


func _on_Spectator_toggled(button_pressed: bool) -> void:
	if match_maker.user_id == user_id:
		_deck_loader.visible = !button_pressed
	var payload := {
		"user_id": user_id,
		"is_spectator": button_pressed
	}
	_nakama_client.socket.send_match_state_async(
			match_maker.joined_match_lobby.match_id,
			NWConst.OpCodes.set_as_spectator,
			JSON.print(payload))


func _on_Kick_pressed() -> void:
	var payload := {
		"user_id": user_id,
	}
	_nakama_client.socket.send_match_state_async(
			match_maker.joined_match_lobby.match_id,
			NWConst.OpCodes.kick_user,
			JSON.print(payload))
