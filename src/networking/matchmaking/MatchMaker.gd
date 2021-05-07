class_name NWMatchMaker
extends PanelContainer


const _MATCH_LOBBY_SCENE_PATH = CFConst.NAKAMA_MATCHMAKING_PATH + "MatchLobbyObject.tscn"
const _MATCH_LOBBY_SCENE = preload(_MATCH_LOBBY_SCENE_PATH)
export(PackedScene) var match_lobby_scene = _MATCH_LOBBY_SCENE
const _PLAYER_LOBBY_SCENE_PATH = CFConst.NAKAMA_MATCHMAKING_PATH + "PlayerLobbyObject.tscn"
const _PLAYER_LOBBY_SCENE = preload(_PLAYER_LOBBY_SCENE_PATH)
export(PackedScene) var player_lobby_scene = _PLAYER_LOBBY_SCENE

var joined_match_lobby: NWMatchLobbyObject
var user_id : String setget ,get_user_id
# If I set the variable directly here, for some reason the static typing
# stops working
onready var nakama_client : CFNakamaClient
onready var notice := $VBC/NoticeLabel
onready var entered_lobby = $VBC/HSplitContainer/CurrentMatch

onready var _authenticate_button = $VBC/HBC/Authenticate
onready var _connection_status = $VBC/HBC/ConnectionStatus
onready var _new_match_name = $VBC/HBoxContainer/NewMatchName
onready var _matches_list = $VBC/HSplitContainer/ScrollContainer/Matches
onready var _current_match_name_label = $VBC/HSplitContainer/CurrentMatch/HBC/MatchName
onready var _start_match_button = $VBC/HSplitContainer/CurrentMatch/HBC/StartMatch
onready var _create_match_button = $VBC/HBoxContainer/CreateMatch
onready var _exit_match_button = $VBC/HSplitContainer/CurrentMatch/HBC/ExitMatch
onready var _timer = $LobbyRefresh
onready var _lobby_player_list = $VBC/HSplitContainer/CurrentMatch/Players

func _ready() -> void:
	notice.hide_delay = 4
	nakama_client = cfc.nakama_client
	if cfc.game_settings.has('nakama_auth_token'):
		var session = nakama_client.restore_session()
		if session is GDScriptFunctionState:
			session = yield(session, "completed")
		_finalize_authentication(session)
	_authenticate_button.get_popup().connect("index_pressed", self, "_on_auth_selected")
	# warning-ignore:return_value_discarded
	nakama_client.socket.connect("received_notification", self, "_on_notification")
	#warning-ignore: return_value_discarded
	nakama_client.socket.connect("received_match_state", self, "_on_received_match_state")
	_timer.connect("timeout", self, "refresh_available_matches")

func get_user_id() -> String:
	return(nakama_client.session.user_id)

func _on_CreateMatch_pressed() -> void:
	# We disable the button to prevent the user from breaking the code
	# by spamming it
	_create_match_button.disabled = true
	if is_instance_valid(joined_match_lobby):
		yield(joined_match_lobby.exit_lobby(),"completed")
	var payload := {"label": _new_match_name.text}
	var new_match: NakamaAPI.ApiRpc = yield(
			nakama_client.client.rpc_async(
			nakama_client.session, "create_match", JSON.print(payload)),
			"completed"
	)
	var new_match_result = JSON.parse(new_match.payload).result
#	print_debug(new_match_result)
	# If the match create failed, we don't want to proceed further
	if new_match_result:
		var new_lobby := _add_match_lobby(_new_match_name.text, new_match_result.matchid)
		# We automatically join the game we created
		yield(new_lobby.join_lobby(false), "completed")
	notice.set_notice("Match '" + _new_match_name.text + "' Created", NoticeLabel.FontColor.GLOW_BLUE)
	_create_match_button.disabled = false

func _on_auth_selected(index: int) -> void:
	var pop : PopupMenu = _authenticate_button.get_popup()
	notice.set_notice("Attempting Authentication. Please wait...", NoticeLabel.FontColor.GLOW_GREEN)
	var session: NakamaSession = yield(
			nakama_client.authenticate(pop.get_item_text(index), 'CGFNakamaDemo'),
			"completed"
	)
	nakama_client.authenticate(pop.get_item_text(index), 'CGFNakamaDemo')
	nakama_client.curr_email = pop.get_item_text(index)
	nakama_client.curr_pass = 'CGFNakamaDemo'
	_finalize_authentication(session)

func _finalize_authentication(session: NakamaSession) -> void:
#	print_debug(session.valid, session.expired)
	if session.valid and not session.expired:
		_connection_status.text = "Authenticated As: " + session.username
		_new_match_name.text = session.username + "'s game"
		_create_match_button.disabled = false
		notice.set_notice("Authenticated succesfully as " + session.username, NoticeLabel.FontColor.GLOW_GREEN)
	elif session.valid and session.expired:
		if is_instance_valid(joined_match_lobby):
			yield(joined_match_lobby.exit_lobby(false),"completed")
		notice.set_notice("Session expired. Please login again!", NoticeLabel.FontColor.GLOW_RED)
	elif not session.valid:
		if is_instance_valid(joined_match_lobby):
			yield(joined_match_lobby.exit_lobby(false),"completed")		
		notice.set_notice("Multiplayer Server appears to be down!", NoticeLabel.FontColor.GLOW_RED)

func refresh_available_matches() -> void:
	var matches: NakamaAPI.ApiRpc = yield(
		nakama_client.client.rpc_async(nakama_client.session, "get_all_matches", ""), "completed"
	)
#	print_debug(matches, nakama_client.session.valid, nakama_client.session.expired)
	if matches.exception or nakama_client.session.expired:
		if is_instance_valid(joined_match_lobby):
			yield(joined_match_lobby.exit_lobby(false),"completed")
		if nakama_client.session.expired or matches.exception.status_code == 401:
			notice.set_notice(
					"Authentication expired! Please authenticate again.",
					NoticeLabel.FontColor.GLOW_RED)
		else:
			notice.set_notice(
					"Multiplayer Server appears to be down!",
					NoticeLabel.FontColor.GLOW_RED)
		for m in _matches_list.get_children():
			m.queue_free()
		return
	var payload = JSON.parse(matches.payload).result
#	print_debug(payload)
	# This variable will hold all ID for existing lobbies
	var current_lobbies : Array
	# We first clean stale lobbies
	for m in _matches_list.get_children():
		var lobby_still_exists := false
		for curr_match in payload:
			if m.match_id == curr_match.match_id:
				lobby_still_exists = true
		if not lobby_still_exists:
			if m == joined_match_lobby:
				joined_match_lobby.exit_lobby()
			m.queue_free()
		else:
			current_lobbies.append(m.match_id)
	if payload:
		for curr_match in payload:
			if not curr_match.match_id in current_lobbies:
				var created_lobby := _add_match_lobby(
						curr_match.label, curr_match.match_id)
#	print_debug(payload)

# Creates a match lobby node and returns it
func _add_match_lobby(match_label: String, match_id: String) -> NWMatchLobbyObject:
	var lobby_object : NWMatchLobbyObject = match_lobby_scene.instance()
	_matches_list.add_child(lobby_object)
	lobby_object.setup(match_label, match_id, self)
	return(lobby_object)


# Creates a player lobby node and returns it
func _add_lobby_player(username: String, user_id: String, lobby_owner_id) -> NWPlayerLobbyObject:
#	print_debug("Name: " + player_name + " ID: " + player_id)
	var player_object : NWPlayerLobbyObject = player_lobby_scene.instance()
	_lobby_player_list.add_child(player_object)
	player_object.setup(username, user_id, self, lobby_owner_id)
#	print_debug(player_object.player_id)
	return(player_object)

func clear_players() -> void:
	for p in _lobby_player_list.get_children():
		p.queue_free()


func _on_notification(p_notification : NakamaAPI.ApiNotification):
	print_debug(p_notification)
	print_debug(p_notification.content)

func _on_NewMatchName_text_entered(new_text: String) -> void:
	if not _create_match_button.disabled:
		_on_CreateMatch_pressed()

func _on_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var state : Dictionary = JSON.parse(match_state.data).result
	match code:
		NWConst.OpCodes.match_terminating:
			joined_match_lobby.exit_lobby(false)
			notice.set_notice("Lobby terminated because host left!", NoticeLabel.FontColor.GLOW_BLUE)
		NWConst.OpCodes.update_lobby:
			var current_players : Array
			for p in _lobby_player_list.get_children():
				var player_still_exists := false
				for presence in state.presences:
#					print_debug(p.player_id + '==' + presence)
					if p.user_id == presence:
						player_still_exists = true
				if not player_still_exists:
					p.queue_free()
#					print_debug('aa')
				else:
					if p.user_id in state.kicked_users:
						if p.user_id == get_user_id():
							notice.set_notice(
									"You have been kicked by game owner!",
									NoticeLabel.FontColor.GLOW_BLUE)
							joined_match_lobby.exit_lobby(false)
						else:
							notice.set_notice(
									"Player " + p.username + " kicked!",
									NoticeLabel.FontColor.GLOW_BLUE)
					current_players.append(p.user_id)
			for presence in state.presences:
				if not presence in current_players:
#						print_debug(raw.lobby_owner,presence)
					_add_lobby_player(
							state.presences[presence].username,
							presence,
							state.lobby_owner)
			for p in _lobby_player_list.get_children():
				for presence in state.presences:
					if p.user_id == presence:
						p.set_status(
								# The user_id might not be in the players
								# dict yet, so we send null in that case.
								state.players.get(p.user_id),
								state.spectators[p.user_id],
								p.user_id in state.ready_users,
								p.user_id == get_user_id())
			var start_button_text := "Unready"
			if get_user_id() in state.ready_users:
				if state.lobby_owner == get_user_id():
					if check_if_all_ready(state.presences, state.ready_users):
						start_button_text = "Start Match"
					else:
						start_button_text = "Force Match Start"
			else:
				start_button_text = "Ready"
			_start_match_button.text = start_button_text
		NWConst.OpCodes.update_state:
			print_debug(state)

#	print(code,state)
#	print_debug(joined_match_lobby)

func _on_ExitMatch_pressed() -> void:
	# Just in case...
	if is_instance_valid(joined_match_lobby):
		joined_match_lobby.exit_lobby()
	else:
		joined_match_lobby = null
		entered_lobby.visible = false
		clear_players()


func _on_StartMatch_pressed() -> void:
	nakama_client.socket.send_match_state_async(
			joined_match_lobby.match_id,
			NWConst.OpCodes.ready_start,
			JSON.print({}))

func check_if_all_ready(presences, ready_players) -> bool:
	var all_ready := true
	for presence in presences:
		if not presence in ready_players:
			all_ready = false
	return(all_ready)
