tool
extends Node

# The default host address of the server.
const DEFAULT_HOST : String = "127.0.0.1"

# The default port number of the server.
const DEFAULT_PORT : int = 7350

# The default timeout for the connections.
const DEFAULT_TIMEOUT = 3

# The default protocol scheme for the client connection.
const DEFAULT_CLIENT_SCHEME : String = "http"

# The default protocol scheme for the socket connection.
const DEFAULT_SOCKET_SCHEME : String = "ws"

# The default log level for the Nakama logger.
const DEFAULT_LOG_LEVEL = NakamaLogger.LOG_LEVEL.DEBUG

var _http_adapter = null
var logger = NakamaLogger.new()

func get_client_adapter() -> NakamaHTTPAdapter:
	if _http_adapter == null:
		_http_adapter = NakamaHTTPAdapter.new()
		_http_adapter.logger = logger
		_http_adapter.name = "NakamaHTTPAdapter"
		add_child(_http_adapter)
	return _http_adapter

func create_socket_adapter() -> NakamaSocketAdapter:
	var adapter = NakamaSocketAdapter.new()
	adapter.name = "NakamaWebSocketAdapter"
	adapter.logger = logger
	add_child(adapter)
	return adapter

func create_client(p_server_key : String,
		p_host : String = DEFAULT_HOST,
		p_port : int = DEFAULT_PORT,
		p_scheme : String = DEFAULT_CLIENT_SCHEME,
		p_timeout : int = DEFAULT_TIMEOUT,
		p_log_level : int = DEFAULT_LOG_LEVEL) -> NakamaClient:
	logger._level = p_log_level
	return NakamaClient.new(get_client_adapter(), p_server_key, p_scheme, p_host, p_port, p_timeout)

func create_socket(p_host : String = DEFAULT_HOST,
		p_port : int = DEFAULT_PORT,
		p_scheme : String = DEFAULT_SOCKET_SCHEME) -> NakamaSocket:
	return NakamaSocket.new(create_socket_adapter(), p_host, p_port, p_scheme, true)

func create_socket_from(p_client : NakamaClient) -> NakamaSocket:
	var scheme = "ws"
	if p_client.scheme == "https":
		scheme = "wss"
	return NakamaSocket.new(create_socket_adapter(), p_client.host, p_client.port, scheme, true)
