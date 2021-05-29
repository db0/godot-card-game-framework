-- Module that controls the game world. The world's state is updated every `tickrate` in the
-- `match_loop()` function.

local match_control = {}

local nk = require("nakama")

local MIN_PLAYERS_REQUIRED = 2

local uses_single_board = true

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function tablefind(tab, val)
    for key, value in pairs(tab) do
        if value == el then
            return key
        end
    end
end

-- Returns true when there's a player present that needs to be kicked (is in the state.kicked_users)
local function need_to_kick(state)
    for presence, value in ipairs(state.presences) do
        if has_value(state.kicked_users, presence) then
			return true
		end
    end
end

-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {
    card_created = 1,
    card_deleted = 2,
    cards_updated = 3,
    update_state = 4,
	deck_loaded = 5,
	set_as_spectator = 6,
	update_lobby = 7,
	match_terminating = 8,
	kick_user = 9,
	ready_start = 10,
	register_containers = 11,
	container_shuffled = 12
}

-- Command pattern table for boiler plate updates that uses data and state.
local commands = {}

-- Updates the position in the game state
commands[OpCodes.card_created] = function(data, state)
    local card_id = data.card_id
    if state.cards[card_id] == nil then
        state.cards[card_id] = {}
		state.cards[card_id]["owner"] = data.owner
		state.cards[card_id]["name"] = data.card_name
		state.cards[card_id]["position"] = data.position
		state.cards[card_id]["container"] = data.container
	else
		state.cards[card_id]["owner"] = data.owner
		state.cards[card_id]["name"] = data.card_name
		state.cards[card_id]["position"] = data.position
		state.cards[card_id]["container"] = data.container
    end
end

-- Updates the horizontal input direction in the game state
commands[OpCodes.card_deleted] = function(data, state)
    local card_id = data.card_id
end

commands[OpCodes.cards_updated] = function(data, state)
	-- The payload for this function contains a dictionary of cards to be updated
	-- each key is an index in the state.cards array
	-- nk.logger_info("Cards updated")
	for index, card_state in pairs(data.cards) do
		for key, value in pairs(card_state) do
			-- nk.logger_info(string.format("%s CARD: key %s. value %s", index, key, value))
			state.cards[tonumber(index)][key] = value
		end
	end
	-- for index, card_state in pairs(state.cards) do
		-- for key, value in pairs(card_state) do
			-- nk.logger_info(string.format("%s CARD: key %s. value %s", index, key, value))
		-- end
	-- end	
end

commands[OpCodes.container_shuffled] = function(data, state)
	-- The payload for this function contains a dictionary of cards to be updated
	-- each key is an index in the state.cards array
	-- nk.logger_info("Cards updated")
	table.insert(state.shuffled_containers, data.container_id)
end

commands[OpCodes.deck_loaded] = function(data, state)
    local player_id = data.sender_id
    local deck = data.deck
	state.players[player_id] = deck
end

commands[OpCodes.set_as_spectator] = function(data, state)
    local spectator_id = data.user_id
    local is_spectator = data.is_spectator
	local sender_id = data.sender_id
	-- The lobby owner is allowed to set other players as spectators
	if spectator_id == sender_id or sender_id == state.lobby_owner then
		state.spectators[spectator_id] = is_spectator
	else
		nk.logger_warn(string.format("Non-lobby owner %s attempted to change spectator status of %s", sender_id, spectator_id))
	end
end

commands[OpCodes.kick_user] = function(data, state)
    local user_to_kick = data.user_id
	local sender_id = data.sender_id
	-- The lobby owner is the only one allowed to kick others
	if sender_id == state.lobby_owner then
		if not has_value(state.kicked_users, user_to_kick) then
			table.insert(state.kicked_users,user_to_kick)
			nk.logger_info(string.format("User %s Kicked from lobby by %s", user_to_kick, sender_id))
		end
	else
		nk.logger_warn(string.format("Non-lobby owner %s attempted to kick %s", sender_id, user_to_kick))
	end
end


commands[OpCodes.ready_start] = function(data, state)
	local sender_id = data.sender_id
	if not has_value(state.ready_users, sender_id) then
		table.insert(state.ready_users,sender_id)
	else
		if sender_id == state.lobby_owner then
			for player, deck in pairs(state.players) do
				for card_name, card_count in pairs(deck.cards) do
					for i = 1,card_count,1 do
						card_reference = {}
						card_reference['card_name'] = card_name
						card_reference['owner'] = player						
						table.insert(state.cards,card_reference)
					end
					state.game_started = true
				end
			end
		else
			table.remove(state.ready_users, tablefind(state.ready_users,sender_id))
		end
	end
end


commands[OpCodes.register_containers] = function(data, state)
	local containers = data.containers
	if uses_single_board then
		for index, name in ipairs(containers) do
			if not has_value(state.containers, name) then
				table.insert(state.containers, name)
			end
		end
	else
		local sender_id = data.sender_id
		if state.containers[sender_id] == nil then
			state.containers[sender_id] = {}
		end	
		for index, name in ipairs(containers) do
			if not has_value(state.containers[sender_id], name) then
				table.insert(state.containers[sender_id], name)
			end
		end
	end
end


-- When the match is initialized. Creates empty tables in the game state that will be populated by
-- clients.
function match_control.match_init(context, params)
    local gamestate = {
        presences = {},
		cards = {},
		containers = {},
		shuffled_containers = {},
		players = {},
		spectators = {},
		ready_users = {},
		kicked_users = {},
		game_started = false,
		lobby_owner = params.creator_id
    }
	-- for k, v in pairs(context) do nk.logger_info(string.format("CONTEXT: %s : %s", k,v)) end
	-- nk.logger_info(string.format("Lobby Owner %s", params.creator_id))
    local tickrate = 3
	local label = "CGF Game"
	if params.label ~= nil then
		label = params.label
	end
	nk.logger_info(string.format("Params: %s", nk.json_encode(params)))
	nk.logger_info(string.format("Game Label: %s", label))
	nk.logger_info(string.format("Game Label: %s", params.label))
    return gamestate, tickrate, label
end

-- When someone tries to join the match. Checks if someone is already logged in and blocks them from
-- doing so if so.
function match_control.match_join_attempt(_, _, _, state, presence, _)
    if state.presences[presence.user_id] ~= nil then
        return state, false, "User already joined."
    end
    if state.game_started then
        return state, false, "Game has already started."
    end
    if has_value(state.kicked_users, presence.user_id) then
        return state, false, "Player has been kicked."
    end
    return state, true
end

-- When someone does join the match. Initializes their entries in the game state tables with dummy
-- values until they spawn in.
function match_control.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = presence
		state.spectators[presence.user_id] = false
    end

    return state
end


function match_control.match_leave(context, dispatcher, tick, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = nil
        state.players[presence.user_id] = nil
        state.spectators[presence.user_id] = nil
		-- nk.logger_debug(string.format("Player exited: %s. Lobby Owner: %s", presence.user_id, state.lobby_owner))
		if presence.user_id == state.lobby_owner and not state.game_started then
			-- Returning nil is the only way to kill a match
			dispatcher.broadcast_message(OpCodes.match_terminating, '{}')
			return nil
		end
    end
    return state
end

-- Called `tickrate` times per second. Handles client messages and sends game state updates. Uses
-- boiler plate commands from the command pattern except when specialization is required.
function match_control.match_loop(context, dispatcher, tick, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code
        local decoded = nk.json_decode(message.data)
		-- We also send over the user ID of the user who sent the message
		-- As some messages are not allowed to be sent by anyone else but the lobby owner (e.g. kick)
		decoded['sender_id'] = message.sender.user_id

        -- Run boiler plate commands (state updates.)
        local command = commands[op_code]
        if command ~= nil then
            commands[op_code](decoded, state)
        end
    end
	if state.game_started then
		local data = {
			cards = state.cards,
			containers = state.containers,
			shuffled_containers = state.shuffled_containers
		}
		local encoded = nk.json_encode(data)
		dispatcher.broadcast_message(OpCodes.update_state, encoded)
		-- After we notify everyone that a container has been shuffled, we remove the notification from future ticks
		for index, container_id in ipairs(state.shuffled_containers) do
			table.remove(state.shuffled_containers, index)
		end
	else
		local data = {
			presences = state.presences,
			players = state.players,
			spectators = state.spectators,
			ready_users = state.ready_users,
			lobby_owner = state.lobby_owner,
			kicked_users = state.kicked_users
		}
		local encoded = nk.json_encode(data)
		-- nk.logger_info(string.format("Sending lobby state: %s", encoded))
		dispatcher.broadcast_message(OpCodes.update_lobby, encoded)
	end
	if need_to_kick(state) then
		dispatcher.match_kick(state.kicked_users)
	end
    return state
end

function match_control.match_terminate(context, dispatcher, tick, state, presences)
    return state
end

return match_control
