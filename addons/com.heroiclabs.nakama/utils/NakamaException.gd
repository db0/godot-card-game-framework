extends Reference

# An exception generated during a request.
# Usually contains at least an error message.
class_name NakamaException

var status_code : int = -1 setget _no_set
var grpc_status_code : int = -1 setget _no_set
var message : String = "" setget _no_set

func _no_set(_p):
	pass

func _init(p_message : String = "", p_status_code : int = -1, p_grpc_status_code : int = -1):
	status_code = p_status_code
	grpc_status_code = p_grpc_status_code
	message = p_message

func _to_string() -> String:
	return "NakamaException(StatusCode={%s}, Message='{%s}', GrpcStatusCode={%s})" % [status_code, message, grpc_status_code]
