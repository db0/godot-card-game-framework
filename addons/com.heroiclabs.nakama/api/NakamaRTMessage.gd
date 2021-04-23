extends Reference
class_name NakamaRTMessage

# Send a channel join message to the server.
class ChannelJoin:

	const _SCHEMA = {
		"persistence": {"name": "persistence", "type": TYPE_BOOL, "required": true},
		"hidden": {"name": "hidden", "type": TYPE_BOOL, "required": true},
		"target": {"name": "target", "type": TYPE_STRING, "required": true},
		"type": {"name": "type", "type": TYPE_INT, "required": true},
	}

	enum ChannelType {
		# A chat room which can be created dynamically with a name.
		Room = 1,
		# A private chat between two users.
		DirectMessage = 2,
		# A chat within a group on the server.
		Group = 3
	}

	var persistence : bool
	var hidden : bool
	var target : String
	var type : int

	func _init(p_target : String, p_type : int, p_persistence : bool, p_hidden : bool):
		persistence = p_persistence
		hidden = p_hidden
		target = p_target
		type = p_type if p_type >= ChannelType.Room and p_type <= ChannelType.Group else 0 # Will cause error server side

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "channel_join"

	func _to_string():
		return "ChannelJoin<persistence=%s, hidden=%s, target=%s, type=%d>" % [persistence, hidden, target, type]


# A leave message for a match on the server.
class ChannelLeave extends NakamaAsyncResult:

	const _SCHEMA = {
		"channel_id": {"name": "channel_id", "type": TYPE_STRING, "required": true}
	}
	var channel_id : String

	func _init(p_channel_id : String):
		channel_id = p_channel_id

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "channel_leave"

	func _to_string():
		return "ChannelLeave<channel_id=%s>" % [channel_id]


class ChannelMessageRemove extends NakamaAsyncResult:

	const _SCHEMA = {
		"channel_id": {"name": "channel_id", "type": TYPE_STRING, "required": true},
		"message_id": {"name": "message_id", "type": TYPE_STRING, "required": true}
	}

	var channel_id : String
	var message_id : String

	func _init(p_channel_id : String, p_message_id):
		channel_id = p_channel_id
		message_id = p_message_id

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "channel_message_remove"

	func _to_string():
		return "ChannelMessageRemove<channel_id=%s, message_id=%s>" % [channel_id, message_id]


# Send a chat message to a channel on the server.
class ChannelMessageSend extends NakamaAsyncResult:

	const _SCHEMA = {
		"channel_id": {"name": "channel_id", "type": TYPE_STRING, "required": true},
		"content": {"name": "content", "type": TYPE_STRING, "required": true}
	}

	var channel_id : String
	var content : String

	func _init(p_channel_id : String, p_content):
		channel_id = p_channel_id
		content = p_content

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "channel_message_send"

	func _to_string():
		return "ChannelMessageSend<channel_id=%s, content=%s>" % [channel_id, content]


class ChannelMessageUpdate extends NakamaAsyncResult:

	const _SCHEMA = {
		"channel_id": {"name": "channel_id", "type": TYPE_STRING, "required": true},
		"message_id": {"name": "message_id", "type": TYPE_STRING, "required": true},
		"content": {"name": "content", "type": TYPE_STRING, "required": true}
	}

	var channel_id : String
	var message_id : String
	var content : String

	func _init(p_channel_id : String, p_message_id, p_content : String):
		channel_id = p_channel_id
		message_id = p_message_id
		content = p_content

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "channel_message_update"

	func _to_string():
		return "ChannelMessageUpdate<channel_id=%s, message_id=%s, content=%s>" % [channel_id, message_id, content]

# A create message for a match on the server.
class MatchCreate extends NakamaAsyncResult:

	const _SCHEMA = {}

	func _init():
		pass

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "match_create"

	func _to_string():
		return "MatchCreate<>"


# A join message for a match on the server.
class MatchJoin extends NakamaAsyncResult:

	const _SCHEMA = {
		"match_id": {"name": "match_id", "type": TYPE_STRING, "required": false},
		"token": {"name": "token", "type": TYPE_STRING, "required": false},
		"metadata": {"name": "metadata", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_STRING},
	}

	# These two are mutually exclusive and set manually by socket for now, so use null.
	var match_id = null
	var token = null
	var metadata = null

	func _init(p_ex=null).(p_ex):
		pass

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "match_join"

	func _to_string():
		return "MatchJoin<match_id=%s, token=%s, metadata=%s>" % [match_id, token, metadata]


# A leave message for a match on the server.
class MatchLeave extends NakamaAsyncResult:

	const _SCHEMA = {
		"match_id": {"name": "match_id", "type": TYPE_STRING, "required": true}
	}
	var match_id : String

	func _init(p_match_id : String):
		match_id = p_match_id

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "match_leave"

	func _to_string():
		return "MatchLeave<match_id=%s>" % [match_id]


# Send new state to a match on the server.
class MatchDataSend extends NakamaAsyncResult:

	const _SCHEMA = {
		"match_id": {"name": "match_id", "type": TYPE_STRING, "required": true},
		"op_code": {"name": "op_code", "type": TYPE_INT, "required": true},
		"presences": {"name": "presences", "type": TYPE_ARRAY, "required": false, "content": "UserPresences"},
		"data": {"name": "data", "type": TYPE_STRING, "required": true},
	}

	var match_id : String
	var presences = null
	var op_code : int
	var data : String

	func _init(p_match_id : String, p_op_code : int, p_data : String, p_presences):
		match_id = p_match_id
		presences = p_presences
		op_code = p_op_code
		data = p_data

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key():
		return "match_data_send"

	func _to_string():
		return "MatchDataSend<match_id=%s, op_code=%s, presences=%s, data=%s>" % [match_id, op_code, presences, data]


# Add the user to the matchmaker pool with properties.
class MatchmakerAdd extends NakamaAsyncResult:

	const _SCHEMA = {
		"query": {"name": "query", "type": TYPE_STRING, "required": true},
		"max_count": {"name": "max_count", "type": TYPE_INT, "required": true},
		"min_count": {"name": "min_count", "type": TYPE_INT, "required": true},
		"numeric_properties": {"name": "numeric_properties", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_REAL},
		"string_properties": {"name": "string_properties", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_STRING},
	}

	var query : String = "*"
	var max_count : int = 8
	var min_count : int = 2
	var string_properties : Dictionary
	var numeric_properties : Dictionary

	func _no_set(_val):
		return

	func _init(p_query : String = "*", p_min_count : int = 2, p_max_count : int = 8,
			p_string_props : Dictionary = Dictionary(), p_numeric_props : Dictionary = Dictionary()):
		query = p_query
		min_count = p_min_count
		max_count = p_max_count
		string_properties = p_string_props
		numeric_properties = p_numeric_props

	func serialize() -> Dictionary:
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "matchmaker_add"

	func _to_string():
		return "MatchmakerAdd<query=%s, max_count=%d, min_count=%d, numeric_properties=%s, string_properties=%s>" % [query, max_count, min_count, numeric_properties, string_properties]


# Remove the user from the matchmaker pool by ticket.
class MatchmakerRemove extends NakamaAsyncResult:

	const _SCHEMA = {
		"ticket": {"name": "ticket", "type": TYPE_STRING, "required": true}
	}

	var ticket : String

	func _init(p_ticket : String):
		ticket = p_ticket

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "matchmaker_remove"

	func _to_string():
		return "MatchmakerRemove<ticket=%s>" % [ticket]


# Follow one or more other users for status updates.
class StatusFollow extends NakamaAsyncResult:

	const _SCHEMA = {
		"user_ids": {"name": "user_ids", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_STRING},
		"usernames": {"name": "usernames", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_STRING},
	}

	var user_ids := PoolStringArray()
	var usernames := PoolStringArray()

	func _init(p_ids : PoolStringArray, p_usernames : PoolStringArray):
		user_ids = p_ids
		usernames = p_usernames

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "status_follow"

	func _to_string():
		return "StatusFollow<user_ids=%s, usernames=%s>" % [user_ids, usernames]


# Unfollow one or more users on the server.
class StatusUnfollow extends NakamaAsyncResult:

	const _SCHEMA = {
		"user_ids": {"name": "user_ids", "type": TYPE_DICTIONARY, "required": false, "content": TYPE_STRING},
	}

	var user_ids := PoolStringArray()

	func _init(p_ids : PoolStringArray):
		user_ids = p_ids

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "status_unfollow"

	func _to_string():
		return "StatusUnfollow<user_ids=%s>" % [user_ids]


# Unfollow one or more users on the server.
class StatusUpdate extends NakamaAsyncResult:

	const _SCHEMA = {
		"status": {"name": "status", "type": TYPE_STRING, "required": true},
	}

	var status : String

	func _init(p_status : String):
		status = p_status

	func serialize():
		return NakamaSerializer.serialize(self)

	func get_msg_key() -> String:
		return "status_update"

	func _to_string():
		return "StatusUpdate<status=%s>" % [status]
