tool
extends Node

# An adapter which implements the HTTP protocol.
class_name NakamaHTTPAdapter

# The logger to use with the adapter.
var logger : Reference = NakamaLogger.new()

var _pending = {}
var id : int = 0

# Send a HTTP request.
# @param method - HTTP method to use for this request.
# @param uri - The fully qualified URI to use.
# @param headers - Request headers to set.
# @param body - Request content body to set.
# @param timeoutSec - Request timeout.
# Returns a task which resolves to the contents of the response.
func send_async(p_method : String, p_uri : String, p_headers : Dictionary, p_body : PoolByteArray, p_timeout : int = 3):
	var req = HTTPRequest.new()
	if OS.get_name() != 'HTML5':
		req.use_threads = true # Threads not available nor needed on the web.

	# Parse method
	var method = HTTPClient.METHOD_GET
	if p_method == "POST":
		method = HTTPClient.METHOD_POST
	elif p_method == "PUT":
		method = HTTPClient.METHOD_PUT
	elif p_method == "DELETE":
		method = HTTPClient.METHOD_DELETE
	elif p_method == "HEAD":
		method = HTTPClient.METHOD_HEAD
	var headers = PoolStringArray()

	# Parse headers
	headers.append("Accept: application/json")
	for k in p_headers:
		headers.append("%s: %s" % [k, p_headers[k]])

	# Handle timeout for 3.1 compatibility
	id += 1
	_pending[id] = [req, OS.get_ticks_msec() + (p_timeout * 1000)]

	logger.debug("Sending request [ID: %d, Method: %s, Uri: %s, Headers: %s, Body: %s, Timeout: %d]" % [
		id, p_method, p_uri, p_headers, p_body.get_string_from_utf8(), p_timeout
	])

	add_child(req)
	return _send_async(req, p_uri, headers, method, p_body, id, _pending, logger)

func _process(delta):
	# Handle timeout for 3.1 compatibility
	var ids = _pending.keys()
	for id in ids:
		var p = _pending[id]
		if p[0].is_queued_for_deletion():
			_pending.erase(id)
			continue
		if p[1] < OS.get_ticks_msec():
			logger.debug("Request %d timed out" % id)
			p[0].cancel_request()
			_pending.erase(id)
			p[0].emit_signal("request_completed", HTTPRequest.RESULT_REQUEST_FAILED, 0, PoolStringArray(), PoolByteArray())

static func _send_async(request : HTTPRequest, p_uri : String, p_headers : PoolStringArray,
		p_method : int, p_body : PoolByteArray, p_id : int, p_pending : Dictionary, logger : NakamaLogger):

	var err = request.request(p_uri, p_headers, true, p_method, p_body.get_string_from_utf8())
	if err != OK:
		yield(request.get_tree(), "idle_frame")
		logger.debug("Request %d failed to start, error: %d" % [p_id, err])
		request.queue_free()
		return NakamaException.new("Request failed")

	var args = yield(request, "request_completed")
	var result = args[0]
	var response_code = args[1]
	var _headers = args[2]
	var body = args[3]

	# Will be deleted next frame
	if not request.is_queued_for_deletion():
		request.queue_free()
		p_pending.erase(p_id)

	if result != HTTPRequest.RESULT_SUCCESS:
		logger.debug("Request %d failed with result: %d, response code: %d" % [
			p_id, result, response_code
		])
		return NakamaException.new("HTTPRequest failed!", result)

	var json : JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.error != OK:
		logger.debug("Unable to parse request %d response. JSON error: %d, response code: %d" % [
			p_id, json.error, response_code
		])
		return NakamaException.new("Failed to decode JSON response", response_code)

	if response_code != HTTPClient.RESPONSE_OK:
		var error = ""
		var code = -1
		if typeof(json.result) == TYPE_DICTIONARY:
			error = json.result["error"] if "error" in json.result else str(json.result)
			code = json.result["code"] if "code" in json.result else -1
		else:
			error = str(json.result)
		if typeof(error) == TYPE_DICTIONARY:
			error = JSON.print(error)
		logger.debug("Request %d returned response code: %d, RPC code: %d, error: %s" % [
			p_id, response_code, code, error
		])
		return NakamaException.new(error, response_code, code)

	return json.result
