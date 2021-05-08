class_name NWConst
extends Reference

enum OpCodes {
	card_created = 1,
	card_deleted,
	cards_updated,
	update_state,
	deck_loaded,
	set_as_spectator,
	update_lobby,
	match_terminating,
	kick_user,
	ready_start,
	register_containers,
}

# The path where scenes and scripts customized for this specific game exist
# (e.g. board, card back etc)
const PATH_CORE := "res://src/networking/"
const PATH_CUSTOM := "res://src/multiplayer_demo/"

const PATH_MULTIPLAYER_MATCH := PATH_CORE + "MultiplayerMatch.gd"
