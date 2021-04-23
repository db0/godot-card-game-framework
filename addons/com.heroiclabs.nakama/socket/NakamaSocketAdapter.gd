tool
extends Node

# An adapter which implements a socket with a protocol supported by Nakama.
class_name NakamaSocketAdapter

var _ws := WebSocketClient.new()
var _timeout : int = 30
var _start : int = 0
var logger = NakamaLogger.new()

# A signal emitted when the socket is connected.
signal connected()

# A signal emitted when the socket is disconnected.
signal closed()

# A signal emitted when the socket has an error when connected.
signal received_error(p_exception)

# A signal emitted when the socket receives a message.
signal received(p_bytes) # PoolByteArray

# If the socket is connected.
func is_connected_to_host():
	return _ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED

# If the socket is connecting.
func is_connecting_to_host():
	return _ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTING

# Close the socket with an asynchronous operation.
func close():
	_ws.disconnect_from_host()

# Connect to the server with an asynchronous operation.
# @param p_uri - The URI of the server.
# @param p_timeout - The timeout for the connect attempt on the socket.
func connect_to_host(p_uri : String, p_timeout : int):
	_ws.disconnect_from_host()
	_timeout = p_timeout
	_start = OS.get_unix_time()
	var err = _ws.connect_to_url(p_uri)
	if err != OK:
		logger.debug("Error connecting to host %s" % p_uri)
		call_deferred("emit_signal", "received_error", err)

# Send data to the server with an asynchronous operation.
# @param p_buffer - The buffer with the message to send.
# @param p_reliable - If the message should be sent reliably (will be ignored by some protocols).
func send(p_buffer : PoolByteArray, p_reliable : bool = true) -> int:
	return _ws.get_peer(1).put_packet(p_buffer)

func _process(delta):
	if _ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTING:
		if _start + _timeout < OS.get_unix_time():
			logger.debug("Timeout when connecting to socket")
			emit_signal("received_error", ERR_TIMEOUT)
			_ws.disconnect_from_host()
		else:
			_ws.poll()
	if _ws.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
		_ws.poll()

func _init():
	_ws.connect("data_received", self, "_received")
	_ws.connect("connection_established", self, "_connected")
	_ws.connect("connection_error", self, "_error")
	_ws.connect("connection_closed", self, "_closed")

func _received():
	emit_signal("received", _ws.get_peer(1).get_packet())

func _connected(p_protocol : String):
	_ws.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	emit_signal("connected")

func _error():
	emit_signal("received_error", FAILED)

func _closed(p_clean : bool):
	emit_signal("closed")
