extends NakamaAsyncResult
class_name NakamaSession


var created : bool = false setget _no_set
var token : String = "" setget _no_set
var create_time : int = 0 setget _no_set
var expire_time : int = 0 setget _no_set
var expired : bool = true setget _no_set, is_expired
var vars : Dictionary = {} setget _no_set
var username : String = "" setget _no_set
var user_id : String = "" setget _no_set
var valid : bool = false setget _no_set, is_valid

func _no_set(v):
	return

func is_expired() -> bool:
	return expire_time < OS.get_unix_time()

func is_valid():
	return valid

func _init(p_token = null, p_created : bool = false, p_exception = null).(p_exception):
	if p_token:
		var unpacked = _jwt_unpack(p_token)
		var decoded = {}
		if not validate_json(unpacked):
			decoded = parse_json(unpacked)
			valid = true
		if typeof(decoded) != TYPE_DICTIONARY:
			decoded = {}
		if decoded.empty():
			valid = false
			if p_exception == null:
				_ex = NakamaException.new("Unable to unpack token")

		token = p_token
		created = p_created
		create_time = OS.get_unix_time()
		expire_time = int(decoded.get("exp", 0))
		username = str(decoded.get("usn", ""))
		user_id = str(decoded.get("uid", ""))
		if decoded.has("vrs") and typeof(decoded["vrs"]) == TYPE_DICTIONARY:
			for k in decoded["vrs"]:
				vars[k] = decoded["vrs"][k]

func _to_string():
	if is_exception():
		return get_exception()._to_string()
	return "Session<created=%s, token=%s, create_time=%d, username=%s, user_id=%s, vars=%s>" % [
		created, token, create_time, username, user_id, str(vars)]

func _jwt_unpack(p_token : String) -> String:
	# Hack decode JSON payload from JWT.
	if p_token.find(".") == -1:
		return ""
	var payload = p_token.split('.')[1];
	var pad_length = ceil(payload.length() / 4.0) * 4;
	# Pad base64
	for i in range(0, pad_length - payload.length()):
		payload += "="
	payload = payload.replace("-", "+").replace("_", "/")
	return Marshalls.base64_to_utf8(payload)
