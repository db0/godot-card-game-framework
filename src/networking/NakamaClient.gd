class_name CFNakamaClient
extends Reference

const SCHEME = "http"
const HOST = "193.164.132.214"
const PORT = 7350
const SERVER_KEY = "card_game_framework"

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var curr_email: String
var curr_pass: String

func _init() -> void:
	client = Nakama.create_client(SERVER_KEY, HOST, PORT, SCHEME)
	socket = Nakama.create_socket_from(client)
#	socket.connect("received_notification", self, "_on_notification")
	
func authenticate(email, password) -> bool:
	# Use yield(client.function(), "completed") to wait for the request to complete.
	session = yield(client.authenticate_email_async(email, password), "completed")
	cfc.set_setting('nakama_email', email)
	cfc.set_setting('nakama_auth_token', session.token)
	if session.is_valid():
		print("Authenticated with Nakama succesfully as " + email + ".")
		yield(socket.connect_async(session), "completed")	
	else:
		print("Nakama Authentication failed!")
	return(session)
	
func restore_session() -> bool:
	session = NakamaClient.restore_session(cfc.game_settings.nakama_auth_token)
	if session.valid and not session.expired:
		print("Existing nakama session restored")
		var ret = yield(socket.connect_async(session), "completed")
#		print_debug(ret)
	else:
		if curr_email and curr_pass:
			authenticate(curr_email, curr_pass)
		else:
			print("Nakama session has expired. Please authenticate again!")
	return(session)

func create_match() -> NakamaRTAPI.Match:
	if not session.valid or session.expired:
		if curr_email and curr_pass:
			authenticate(curr_email, curr_pass)
	var created_match : NakamaRTAPI.Match = yield(socket.create_match_async(), "completed")
	if created_match.is_exception():
	  print("An error occured: %s" % created_match)
	return(created_match)

# Returns false if join failed, else returns true
func join_match_async(match_id: String) -> bool:
	var joined_match = yield(socket.join_match_async(match_id), "completed")
	if joined_match.is_exception():
		print("An error occured: %s" % joined_match)
		return(false)
	for presence in joined_match.presences:
		print("User id %s name %s'." % [presence.user_id, presence.username])
	return(true)

# Returns false if join failed, else returns true
func leave_match_async(match_id: String) -> bool:
	var left_match = yield(socket.leave_match_async(match_id), "completed")
	if left_match.is_exception():
		print("An error occured: %s" % left_match)
		return(false)
	return(true)
