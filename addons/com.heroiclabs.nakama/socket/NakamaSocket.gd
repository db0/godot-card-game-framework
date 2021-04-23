extends Reference

# A socket to interact with Nakama server.
class_name NakamaSocket

const ChannelType = NakamaRTMessage.ChannelJoin.ChannelType

# Emitted when a socket is closed.
signal closed()

# Emitted when a socket is connected.
signal connected()

# Emitted when a chat channel message is received
signal received_channel_message(p_channel_message) # ApiChannelMessage

# Emitted when receiving a presence change for joins and leaves with users in a chat channel.
signal received_channel_presence(p_channel_presence) # ChannelPresenceEvent

# Emitted when an error occurs on the socket.
signal received_error(p_error)

# Emitted when receiving a matchmaker matched message.
signal received_matchmaker_matched(p_matchmaker_matched) # MatchmakerMatched

# Emitted when receiving a message from a multiplayer match.
signal received_match_state(p_match_state) # MatchData

# Emitted when receiving a presence change for joins and leaves of users in a multiplayer match.
signal received_match_presence(p_match_presence_event) # MatchPresenceEvent

# Emitted when receiving a notification for the current user.
signal received_notification(p_api_notification) # ApiNotification

# Emitted when receiving a presence change for when a user updated their online status.
signal received_status_presence(p_status_presence_event) # StatusPresenceEvent

# Emitted when receiving a presence change for joins and leaves on a realtime stream.
signal received_stream_presence(p_stream_presence_event) # StreamPresenceEvent

# Emitted when receiving a message from a realtime stream.
signal received_stream_state(p_stream_state) # StreamState

var _adapter : NakamaSocketAdapter
var _free_adapter : bool = false
var _weak_ref : WeakRef
var _base_uri : String
var _responses : Dictionary
var _last_id : int = 1
var _conn : GDScriptFunctionState = null
var logger : NakamaLogger = null

func _resume_conn(p_err : int):
	if _conn:
		if p_err: # Exception
			logger.warning("Connection error: %d" % p_err)
			_conn.resume(NakamaAsyncResult.new(NakamaException.new()))
		else:
			logger.info("Connected!")
			_conn.resume(NakamaAsyncResult.new())
		call_deferred("_survive", _conn)
		_conn = null

func _init(p_adapter : NakamaSocketAdapter,
		p_host : String,
		p_port : int,
		p_scheme : String,
		p_free_adapter : bool = false):
	logger = p_adapter.logger
	_adapter = p_adapter
	_weak_ref = weakref(_adapter)
	var port = ""
	if (p_scheme == "ws" and p_port != 80) or (p_scheme == "wss" and p_port != 443):
		port = ":%d" % p_port
	_base_uri = "%s://%s%s" % [p_scheme, p_host, port]
	_free_adapter = p_free_adapter
	_adapter.connect("closed", self, "_closed")
	_adapter.connect("connected", self, "_connected")
	_adapter.connect("received_error", self, "_error")
	_adapter.connect("received", self, "_received")

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Is this a bug? Why can't I call a function? self is null...
#		_clear_responses()
#		_resume_conn(ERR_FILE_EOF)
		var keys = _responses.keys()
		for k in keys:
			_responses[k].resume(NakamaException.new("Cancelled!"))
		if _conn != null:
			_conn.resume(ERR_FILE_EOF)
			call_deferred("_survive", _conn)
		_conn = null
		if _weak_ref.get_ref() == null:
			return
		_adapter.close()
		if _free_adapter:
			_adapter.queue_free()

func _closed(p_error = null):
	emit_signal("closed")
	_resume_conn(ERR_CANT_CONNECT)
	_clear_responses()

func _error(p_error):
	emit_signal("received_error", p_error)
	_resume_conn(p_error)
	_clear_responses()

func _connected():
	emit_signal("connected")
	_resume_conn(OK)

func _received(p_bytes : PoolByteArray):
	var json_str = p_bytes.get_string_from_utf8()
	var json := JSON.parse(json_str)
	if json.error != OK or typeof(json.result) != TYPE_DICTIONARY:
		logger.error("Unable to parse response: %s" % json_str)
		return
	var dict : Dictionary = json.result
	var cid = dict.get("cid")
	if cid:
		if _responses.has(cid):
			_resume_response(cid, dict)
		else:
			logger.error("Invalid call id received %s" % dict)
	else:
		if dict.has("channel_message"):
			var res = NakamaAPI.ApiChannelMessage.create(NakamaAPI, dict["channel_message"])
			emit_signal("received_channel_message", res)
		elif dict.has("channel_presence_event"):
			var res = NakamaRTAPI.ChannelPresenceEvent.create(NakamaRTAPI, dict["channel_presence_event"])
			emit_signal("received_channel_presence", res)
		elif dict.has("match_data"):
			var res = NakamaRTAPI.MatchData.create(NakamaRTAPI, dict["match_data"])
			emit_signal("received_match_state", res)
		elif dict.has("match_presence_event"):
			var res = NakamaRTAPI.MatchPresenceEvent.create(NakamaRTAPI, dict["match_presence_event"])
			emit_signal("received_match_presence", res)
		elif dict.has("matchmaker_matched"):
			var res = NakamaRTAPI.MatchmakerMatched.create(NakamaRTAPI, dict["matchmaker_matched"])
			emit_signal("received_matchmaker_matched", res)
		elif dict.has("notifications"):
			var res = NakamaAPI.ApiNotificationList.create(NakamaAPI, dict["notifications"])
			for n in res.notifications:
				emit_signal("received_notification", n)
		elif dict.has("status_presence_event"):
			var res = NakamaRTAPI.StatusPresenceEvent.create(NakamaRTAPI, dict["status_presence_event"])
			emit_signal("received_status_presence", res)
		elif dict.has("stream_presence_event"):
			var res = NakamaRTAPI.StreamPresenceEvent.create(NakamaRTAPI, dict["stream_presence_event"])
			emit_signal("received_stream_presence", res)
		elif dict.has("stream_data"):
			var res = NakamaRTAPI.StreamData.create(NakamaRTAPI, dict["stream_data"])
			emit_signal("received_stream_state", res)
		else:
			logger.warning("Unhandled response: %s" % dict)

func _resume_response(p_id : String, p_data):
	if _responses.has(p_id):
		logger.debug("Resuming response: %s: %s" % [p_id, p_data])
		_responses[p_id].resume(p_data)
	else:
		logger.warning("Trying to resume missing response: %s: %s" % [p_id, p_data])

func _cancel_response(p_id : String):
	logger.debug("Cancelling response: %s" % [p_id])
	_resume_response(p_id, NakamaException.new("Request cancelled."))

func _clear_responses():
	var ids = _responses.keys()
	for id in ids:
		_cancel_response(id)

func _survive(p_ref):
	pass

func _parse_result(p_responses : Dictionary, p_id : String, p_type, p_ns : GDScript, p_result_key = null):

	# Specifically defined key, or default for objject
	var result_key = p_result_key
	if p_type != NakamaAsyncResult and result_key == null:
		result_key = p_type.get_result_key()

	# Here we yield and wait
	var data = yield() # Manually resumed
	call_deferred("_survive", p_responses[p_id])
	p_responses.erase(p_id) # Remove this request from the list of responses

	# We got an exception, maybe the task was cancelled?
	if data is NakamaException:
		return p_type.new(data as NakamaException)
	# Error from server
	if data.has("error"):
		var err = data["error"]
		var code = -1
		var msg = str(err)
		if typeof(err) == TYPE_DICTIONARY:
			msg = err.get("message", "")
			code = err.get("code", -1)
		logger.warning("Error response from server: %s" % err)
		return p_type.new(NakamaException.new(msg, code))
	# Simple ack response
	elif p_type == NakamaAsyncResult:
		return NakamaAsyncResult.new()
	# Missing expected result key
	elif not data.has(result_key):
		logger.warning("Missing expected result key: %s" % result_key)
		return p_type.new(NakamaException.new("Missing expected result key: %s" % result_key))
	# All good, proceed with parsing
	else:
		return p_type.create(p_ns, data.get(result_key))

func _send_async(p_message, p_parse_type = NakamaAsyncResult, p_ns = NakamaRTAPI, p_msg_key = null, p_result_key = null):
	logger.debug("Sending async request: %s" % p_message)
	# For messages coming from the API which does not have a key defined, so we can override it
	var msg = p_msg_key
	# For regular RT messages
	if msg == null:
		msg = p_message.get_msg_key()
	var id = str(_last_id)
	_last_id += 1
	_responses[id] = _parse_result(_responses, id, p_parse_type, p_ns, p_result_key)
	var json := JSON.print({
		"cid": id,
		msg: p_message.serialize()
	})
	var err = _adapter.send(json.to_utf8())
	if err != OK:
		call_deferred("_cancel_response", id)
	return _responses[id]

func _connect_function():
	return yield() # Manually resumed

# If the socket is connected.
func is_connected_to_host():
	return _adapter.is_connected_to_host()

# If the socket is connecting.
func is_connecting_to_host():
	return _adapter.is_connecting_to_host()

# Close the socket connection to the server.
func close():
	_adapter.close()

# Connect to the server.
# @param p_session - The session of the user.
# @param p_appear_online - If the user who appear online to other users.
# @param p_connect_timeout - The time allowed for the socket connection to be established.
# Returns a task to represent the asynchronous operation.
func connect_async(p_session : NakamaSession, p_appear_online : bool = false, p_connect_timeout : int = 3):
	var uri = "%s/ws?lang=en&status=%s&token=%s" % [_base_uri, str(p_appear_online).to_lower(), p_session.token]
	logger.debug("Connecting to host: %s" % uri)
	_adapter.connect_to_host(uri, p_connect_timeout)
	_conn = _connect_function()
	return _conn

# Join the matchmaker pool and search for opponents on the server.
# @param p_query - The matchmaker query to search for opponents.
# @param p_min_count - The minimum number of players to compete against in a match.
# @param p_max_count - The maximum number of players to compete against in a match.
# @param p_string_properties - A set of key/value properties to provide to searches.
# @param p_numeric_properties - A set of key/value numeric properties to provide to searches.
# Returns a task which resolves to a matchmaker ticket object.
func add_matchmaker_async(p_query : String = "*", p_min_count : int = 2, p_max_count : int = 8,
		p_string_props : Dictionary = {}, p_numeric_props : Dictionary = {}) -> NakamaRTAPI.MatchmakerTicket:
	return _send_async(
		NakamaRTMessage.MatchmakerAdd.new(p_query, p_min_count, p_max_count, p_string_props, p_numeric_props),
		NakamaRTAPI.MatchmakerTicket
	)

## <summary>
## Create a multiplayer match on the server.
## </summary>
## Returns a task to represent the asynchronous operation.
func create_match_async():
	return _send_async(NakamaRTMessage.MatchCreate.new(), NakamaRTAPI.Match)

# Subscribe to one or more users for their status updates.
# @param p_user_ids - The IDs of users.
# @param p_usernames - The usernames of the users.
# Returns a task which resolves to the current statuses for the users.
func follow_users_async(p_ids : PoolStringArray, p_usernames : PoolStringArray = []) -> NakamaRTAPI.Status:
	return _send_async(NakamaRTMessage.StatusFollow.new(p_ids, p_usernames), NakamaRTAPI.Status)

# Join a chat channel on the server.
# @param p_target - The target channel to join.
# @param p_type - The type of channel to join.
# @param p_persistence - If chat messages should be stored.
# @param p_hidden - If the current user should be hidden on the channel.
# Returns a task which resolves to a chat channel object.
func join_chat_async(p_target : String, p_type : int, p_persistence : bool = false, p_hidden : bool = false) -> NakamaRTAPI.Channel:
	return _send_async(
		NakamaRTMessage.ChannelJoin.new(p_target, p_type, p_persistence, p_hidden),
		NakamaRTAPI.Channel
	)

# Join a multiplayer match with the matchmaker matched object.
# @param p_matched - A matchmaker matched object.
# Returns a task which resolves to a multiplayer match.
func join_matched_async(p_matched):
	var msg := NakamaRTMessage.MatchJoin.new()
	if p_matched.match_id:
		msg.match_id = p_matched.match_id
	else:
		msg.token = p_matched.token
	return _send_async(msg, NakamaRTAPI.Match)

# Join a multiplayer match by ID.
# @param p_match_id - The ID of the match to attempt to join.
# @param p_metadata - An optional set of key-value metadata pairs to be passed to the match handler.
# Returns a task which resolves to a multiplayer match.
func join_match_async(p_match_id : String, p_metadata = null):
	var msg := NakamaRTMessage.MatchJoin.new()
	msg.match_id = p_match_id
	return _send_async(msg, NakamaRTAPI.Match)

# Leave a chat channel on the server.
## @param p_channel_id - The ID of the chat channel to leave.
# Returns a task which represents the asynchronous operation.
func leave_chat_async(p_channel_id : String) -> NakamaAsyncResult:
	return _send_async(NakamaRTMessage.ChannelLeave.new(p_channel_id))

# Leave a multiplayer match on the server.
# @param p_match_id - The multiplayer match to leave.
# Returns a task which represents the asynchronous operation.
func leave_match_async(p_match_id : String) -> NakamaAsyncResult:
	return _send_async(NakamaRTMessage.MatchLeave.new(p_match_id))

# Remove a chat message from a chat channel on the server.
# @param p_channel - The chat channel with the message to remove.
# @param p_message_id - The ID of the chat message to remove.
# Returns a task which resolves to an acknowledgement of the removed message.
func remove_chat_message_async(p_channel_id : String, p_message_id : String):
	return _send_async(
		NakamaRTMessage.ChannelMessageRemove.new(p_channel_id, p_message_id),
		NakamaRTAPI.ChannelMessageAck
	)

# Leave the matchmaker pool with the ticket.
# @param p_ticket - The ticket returned by the matchmaker on join.
# Returns a task which represents the asynchronous operation.
func remove_matchmaker_async(p_ticket : String) -> NakamaAsyncResult:
	return _send_async(NakamaRTMessage.MatchmakerRemove.new(p_ticket))

# Execute an RPC function to the server.
# @param p_func_id - The ID of the function to execute.
# @param p_payload - An (optional) String payload to send to the server.
# Returns a task which resolves to the RPC function response object.
func rpc_async(p_func_id : String, p_payload = null) -> NakamaAPI.ApiRpc:
	var payload = p_payload
	match typeof(p_payload):
		TYPE_NIL, TYPE_STRING:
			pass
		_:
			payload = JSON.print(p_payload)
	return _send_async(NakamaAPI.ApiRpc.create(NakamaAPI, {
		"id": p_func_id,
		"payload": payload
	}), NakamaAPI.ApiRpc, NakamaAPI, "rpc", "rpc")

# Send input to a multiplayer match on the server.
# When no presences are supplied the new match state will be sent to all presences.
# @param p_match_id - The ID of the match.
# @param p_op_code - An operation code for the input.
# @param p_data - The input data to send.
# @param p_presences - The presences in the match who should receive the input.
# Returns a task which represents the asynchronous operation.
func send_match_state_async(p_match_id, p_op_code : int, p_data : String, p_presences = null):
	var req = _send_async(NakamaRTMessage.MatchDataSend.new(
		p_match_id,
		p_op_code,
		Marshalls.utf8_to_base64(p_data),
		p_presences
	))
	# This do not return a response from server, you don't really need to wait for it.
	req.call_deferred("resume", {})
	call_deferred("_survive", req)
	return req

# Send input to a multiplayer match on the server.
# When no presences are supplied the new match state will be sent to all presences.
# @param p_match_id - The ID of the match.
# @param p_op_code - An operation code for the input.
# @param p_data - The input data to send.
# @param p_presences - The presences in the match who should receive the input.
# Returns a task which represents the asynchronous operation.
func send_match_state_raw_async(p_match_id, p_op_code : int, p_data : PoolByteArray, p_presences = null):
	var req = _send_async(NakamaRTMessage.MatchDataSend.new(
		p_match_id,
		p_op_code,
		Marshalls.raw_to_base64(p_data),
		p_presences
	))
	# This do not return a response from server, you don't really need to wait for it.
	req.call_deferred("resume", {})
	call_deferred("_survive", req)
	return req

# Unfollow one or more users from their status updates.
# @param p_user_ids - An array of user ids to unfollow.
# Returns a task which represents the asynchronous operation.
func unfollow_users_async(p_ids : PoolStringArray):
	return _send_async(NakamaRTMessage.StatusUnfollow.new(p_ids))

# Update a chat message on a chat channel in the server.
# @param p_channel_id - The ID of the chat channel with the message to update.
# @param p_message_id - The ID of the message to update.
# @param p_content - The new contents of the chat message.
# Returns a task which resolves to an acknowledgement of the updated message.
func update_chat_message_async(p_channel_id : String, p_message_id : String, p_content : Dictionary):
	return _send_async(
		NakamaRTMessage.ChannelMessageUpdate.new(p_channel_id, p_message_id, JSON.print(p_content)),
		NakamaRTAPI.ChannelMessageAck
	)

# Update the status for the current user online.
# @param p_status - The new status for the user.
# Returns a task which represents the asynchronous operation.
func update_status_async(p_status : String):
	return _send_async(NakamaRTMessage.StatusUpdate.new(p_status))

# Send a chat message to a chat channel on the server.
# @param p_channel_id - The ID of the chat channel to send onto.
# @param p_content - The contents of the message to send.
# Returns a task which resolves to the acknowledgement of the chat message write.
func write_chat_message_async(p_channel_id : String, p_content : Dictionary):
	return _send_async(
		NakamaRTMessage.ChannelMessageSend.new(p_channel_id, JSON.print(p_content)),
		NakamaRTAPI.ChannelMessageAck
	)
