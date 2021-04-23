class_name NWMatchLobbyObject
extends HBoxContainer

var match_maker
var match_id: String
var _nakama_client: CFNakamaClient

onready var match_name := $MatchName
onready var join_match_button := $JoinMatch

func _ready() -> void:
	pass

func setup(_match_name, _match_id, _match_maker) -> void:
	match_name.text = _match_name
	match_id = _match_id
	match_maker = _match_maker
	_nakama_client = match_maker.nakama_client
	

func join_lobby(notify := true) -> void:
	match_maker.clear_players()
	if is_instance_valid(match_maker.joined_match_lobby):
		yield(match_maker.joined_match_lobby.exit_lobby(), "completed")
	var join_result = yield(_nakama_client.join_match_async(match_id), "completed")
	if join_result:
		match_maker._current_match_name_label.text = match_name.text
		match_maker.entered_lobby.visible = true
		match_maker.joined_match_lobby = self
		join_match_button.disabled = true
		if notify:
			match_maker.notice.set_notice("Lobby '" + match_name.text + "' Joined", NoticeLabel.FontColor.GLOW_BLUE)
	else:
		match_maker.notice.set_notice(
				"Failed to join Lobby '" + match_name.text + "'. ",
				NoticeLabel.FontColor.GLOW_RED)

func exit_lobby(notify := true) -> void:
	yield(_nakama_client.leave_match_async(match_id), "completed")
	match_maker._current_match_name_label.text = 'No Match Joined'
	match_maker.entered_lobby.visible = false
	match_maker.joined_match_lobby = null
	match_maker.clear_players()
	join_match_button.disabled = false
	match_maker.refresh_available_matches()
	if notify:
		match_maker.notice.set_notice(
				"Lobby '" + match_name.text + "' Exited", 
				NoticeLabel.FontColor.GLOW_BLUE)

func _on_JoinMatch_pressed() -> void:
	join_lobby()
