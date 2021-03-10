# This class handles submitting game stats
# to a [CGF-Stats](https://github.com/db0/CGF-Stats) instance
# It requires CFConst.STATS_URI and CFConst.STATS_PORT to be set
# And the game name in the Project > Settings should match the
# game name set when running CGF-Stats.
class_name GameStats
extends Reference

# Stores the unique id for this match. It is used to submit final results
var game_uuid : String
var thread: Thread

# Initiates the game stats for this game as soon as this object is instanced
func _init(deck = {}):
	# We use a thread to avoid hanging while while polling http
	# Since the threaded function can only accept one argument
	# We put everything in a dict
	var userdata = {
		"type": "new_game",
		"game_data": {
			"deck": deck,
			"client": OS.get_name(),
		}
	}
	# HTML5 does not support threaded http calls
	if OS.get_name() == "HTML5":
		call_api(userdata)
	else:
		thread = Thread.new()
		# warning-ignore:return_value_discarded
		thread.start(self, "call_api", userdata)

# Submits results of the game (victory/defeat etc) to the CFG-Stats
func complete_game(game_data):
	# In case the player just clicked the button very fast
	# make sure the previous thread finished running
	if game_uuid != '':
		thread.wait_to_finish()
		thread = Thread.new()
		var userdata = {"type": "complete_game", "game_data": game_data}
		# HTML5 does not support threaded http calls
		if OS.get_name() == "HTML5":
			call_api(userdata)
		else:
			# warning-ignore:return_value_discarded
			thread.start(self, "call_api", userdata)
		# Put a thread.wait_to_finish() somewhere before you reset the whole game
		# To avoid leaving garbage


# Handles calling CGF-Stats for all request types.
func call_api(userdata):
	var type = userdata["type"]
	var game_data = userdata["game_data"]
	# Convert data to json string:
	# Add 'Content-Type' header:
	var err = 0
	# Create the Client.
	var http = HTTPClient.new()
	# Connect to host/port.
	err = http.connect_to_host(CFConst.STATS_URI, CFConst.STATS_PORT)
	# Make sure connection was OK.
	assert(err == OK)

	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING\
			or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")

	# Could not connect
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)

	var headers = ["Content-Type: application/json"]
	match type:
		"new_game":
			var data := {
				"game_name": ProjectSettings.get_setting(
							"application/config/name"),
				# We're expecting the game_data to be deck dict
				"deck": game_data.deck,
				"client": game_data.client,
			}
			var query = JSON.print(data)
			err = http.request(
				HTTPClient.METHOD_POST,
				"/newgame/",
				headers,
				query)
		"complete_game":
			var data := {
				# We're expecting the game_data to be dict
				# with the final game state as "Victory" or "Loss"
				# But your game could pass whatever
				"state": game_data.get('state'),
				"details": game_data.get('details'),
			}
			var query = JSON.print(data)
			err = http.request(
				HTTPClient.METHOD_PUT,
				"/game/" + game_uuid,
				headers,
				query)
	assert(err == OK)
	# Make sure all is OK.
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.		
		http.poll()
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")
	# Make sure request finished well.
	assert(http.get_status() == HTTPClient.STATUS_BODY\
			or http.get_status() == HTTPClient.STATUS_CONNECTED)

	if http.has_response():
		# If there is a response...
		headers = http.get_response_headers_as_dictionary() # Get response headers.
#		print_debug("**headers:\\n", headers) # Show headers.
		if http.get_response_code() == 201:
			# Array that will hold the data.
			var rb = PoolByteArray()
			while http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					if not OS.has_feature("web"):
						# Got nothing, wait for buffers to fill a bit.
						OS.delay_usec(1000)
					else:
						# Synchronous HTTP requests are not supported on the web,
						# so wait for the next main loop iteration.
						yield(Engine.get_main_loop(), "idle_frame")
				else:
					# Append to read buffer.
					rb = rb + chunk
			# Apparently this is wrapped in "double quotes" so we need to strip them
			game_uuid = rb.get_string_from_ascii().strip_edges().lstrip('"').rstrip('"')
		elif http.get_response_code() == 403:
			print_debug("WARNING: Game Stats server reported that this is "\
					+ "the wrong game name! Please check your URL.")
		elif http.get_response_code() == 404:
			print_debug("WARNING: Stats for this game have not been initiated.")
		elif http.get_response_code() == 409:
			print_debug("WARNING: Game has already been resolved.")
		elif http.get_response_code() != 200:
			print_debug("WARNING: Could submit game stats."\
					+ "Server response code:" + str(http.get_response_code()))
	# We don't want to keep the connection open indefinitelly
	http.close()
