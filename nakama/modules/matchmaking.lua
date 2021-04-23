-- Defines remote procedures accessible for clients to call to get information before joining the
-- game world.
--
-- @usage ```gdscript
-- var world: NakamaAPI.ApiRpc = yield(
--     client.rpc_async(session, "get_world_id", ""), "completed"
-- )
-- if world.is_exception():
--     var exception: NakamaException = world.get_exception()
--     print(exception.message)
-- else:
--     print("World id is %s" % world.payload)
-- ```

local nk = require("nakama")

-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {
    new_match_notification = 1
}
local function create_match(context, payload)
	local modulename = "match_control"
	local decoded_payload = nk.json_decode(payload)
	decoded_payload["creator_id"] = context.user_id
	nk.logger_info(string.format("Payload: %s", decoded_payload))
	local matchid = nk.match_create(modulename, decoded_payload)
	nk.logger_info(string.format("Match id %s", matchid))
	-- nk.logger_info(string.format("All Matches %s", nk.json_encode(nk.match_get(matchid))))
	-- nk.notification_send("76a147a1-68e5-4da1-aeb9-a8a6d0d89107", "New match", nk.match_get(matchid), OpCodes.new_match_notification, nil, false)
	-- for _, match in ipairs(nk.match_list()) do
		-- nk.logger_info(string.format("List all Matches2 - Match id %s", match.match_id))
	-- end	
	return nk.json_encode({ matchid = matchid })
end

local function get_all_matches(context, payload)
	local matches = nk.match_list(100)
	for _, match in ipairs(matches) do
		nk.logger_info(string.format("List all Matches - Match id %s", match.match_id))
	end
    return nk.json_encode(matches)
end

local function announce_new_match(context, payload)
	local user_id = "76a147a1-68e5-4da1-aeb9-a8a6d0d89107"
	local sender_id = nil -- "nil" for server sent.
	local content = payload
	nk.logger_info("Testen")
	-- for _, match in ipairs(matches) do
		-- nk.logger_info(string.format("Match id %s", match.match_id))
	-- end		
	local subject = "New match discovered!"
	local code = OpCodes.new_match_notification
	local persistent = false

	nk.notification_send(user_id, subject, content, code, sender_id, persistent)
end


-- RPC registered to Nakama
nk.register_rpc(create_match, "create_match")
nk.register_rpc(get_all_matches, "get_all_matches")
nk.register_req_after(announce_new_match, "MatchCreate")