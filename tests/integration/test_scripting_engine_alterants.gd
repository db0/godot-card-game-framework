extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(0.1), YIELD)
	card = cards[0]
	target = cards[2]

func test_is_cost_with_alterants():
# warning-ignore:return_value_discarded
	board.counters.mod_counter("research", 5, true)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": -1}]}}
	card.scripts = {"manual": {"board": [
			{"name": "mod_counter",
			"is_cost": true,
			"counter_name":  "research",
			"modification": -5},
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 90}]}}
	yield(table_move(card, Vector2(200,200)), "completed")
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),5,
			"Counter not modifed because it brought cost too high")
	assert_eq(card.card_rotation,0,
			"Card not rotated because counter + alterant cost cannot be paid")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": 4}]}}
	cfc.flush_cache()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(board.counters.get_counter("research"),4,
			"Counter modified to modification + alterant")
	assert_eq(card.card_rotation,90,
			"Card rotated because counter + alterant cost can be be paid")

func test_alterants_respect_state():
	target.scripts = {"alterants": {"board": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": 5}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),3,
			"Counter set to the specified amount because alterant not state-applicable")

func test_self_alterants():
	card.scripts = {
		"manual": {
			"hand": [
				{"name": "mod_counter",
				"counter_name":  "research",
				"modification": 3}]},
		"alterants": {
			"hand": [
				{"filter_task": "mod_counter",
				"trigger": "self",
				"filter_counter_name": "research",
				"alteration": 3}
			]
		}
	}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),6,
			"Altered self execution")

func test_alterants_per():
# warning-ignore:return_value_discarded
	board.counters.mod_counter("credits", 10, true)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": "per_counter",
			"per_counter": {"counter_name": "credits"}}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),13,
			"Altered counter per other counter")

func test_alterants_respect_single_tag():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": "FALSE",
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"tags": ["GUT"],
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),3,
			"Counter not altered because single tag doesn't match")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": "GUT",
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),9,
			"Counter altered single tag as string matches")


func test_alterants_respect_muliple_tags():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": ["FALSE"],
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"tags": ["GUT"],
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),3,
			"Counter not altered because tag doesn't match")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": ["GUT"],
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),9,
			"Counter altered because single tag in array matches")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"tags": ["GUT", "CGF"],
			"counter_name":  "research",
			"modification": 3}]}}
	yield(yield_for(0.5), YIELD)
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),15,
			"Counter altered because tag matches one of the tags defined in task")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": ["GUT","FALSE"],
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),18,
			"Counter not altered one of the filtered tags does not match")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_tags": ["GUT","CGF"],
			"filter_counter_name": "research",
			"alteration": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),24,
			"Counter altered because all of filtered tags  match")

func test_different_alterants():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"alteration": 1},
			{"filter_task": "mod_tokens",
			"trigger": "another",
			"alteration": 1},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),4,
			"Research counter not affected by token alterant")

func test_alterants_respect_filter_state():
	var type : String = card.properties["Type"]
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_state_trigger": [{
				"filter_properties": {"Type": type}
			}],
			"alteration": 3},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 1}]}}
	cards[1].scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 1}]}}
	card.execute_scripts()
	cards[1].execute_scripts()
	assert_eq(board.counters.get_counter("research"),5,
			"Research counter not affected by token alterant of not matching trigger card")

func test_alterants_respect_polarity():
# warning-ignore:return_value_discarded
	board.counters.mod_counter("research", 5, true)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": -5}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),5,
			"Alterant cannot turn a positive amount into a negative")
# warning-ignore:return_value_discarded
	board.counters.mod_counter("research", 5, true)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": 5}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": -3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),5,
			"Alterant cannot turn a negative amount into a positive")

func test_counter_alterants():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": 1},
			{"filter_task": "mod_counter",
			"trigger": "another",
			"filter_counter_name": "credits",
			"alteration": 2},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"counter_name":  "research",
			"modification": 3}]}}
	card.execute_scripts()
	assert_eq(board.counters.get_counter("research"),4,
			"Counter set to the specified amount + alterant")
	assert_eq(board.counters.get_counter("credits"),100,
			"Credits counter not modified")

func test_tokens_alterants():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_tokens",
			"trigger": "another",
			"filter_token_name": "industry",
			"alteration": 1},
			{"filter_task": "mod_tokens",
			"trigger": "another",
			"filter_token_name": "blood",
			"alteration": 2},]}}
	card.scripts = {"manual": {"board": [
			{"name": "mod_tokens",
			"subject": "self",
			"modification": 3,
			"token_name":  "industry"}]}}
	yield(table_move(card, Vector2(200,200)), "completed")
	card.execute_scripts()
	var industry_token: Token = card.tokens.get_token("industry")
	var blood_token: Token = card.tokens.get_token("blood")
	assert_not_null(industry_token)
	if industry_token:
		assert_eq(industry_token.count,4,
				"Token set to the specified amount + alterant")
	assert_null(blood_token,
			"Blood token not added")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "mod_tokens",
			"trigger": "another",
			"filter_token_name": "industry",
			"alteration": -2}]}}
	card.execute_scripts()
	if industry_token:
		assert_eq(industry_token.count,5,
				"Increased by the specified amount + alterant")

func test_spawn_card_alterants():
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "spawn_card",
			"trigger": "another",
			"filter_card_name": "Spawn Card",
			"alteration": 3},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"card_name": "Spawn Card",
			"object_count": 1,
			"board_position":  Vector2(200,200)}]}}
	card.execute_scripts()
	assert_eq(4,board.get_card_count(),
		"Correct amount of cards spawned on board")

func test_get_counter_alterants():
	card.scripts = {"alterants": {"hand": [
			{"filter_task": "get_counter",
			"trigger": "another",
			"filter_counter_name": "research",
			"alteration": 3},]}}
	assert_eq(board.counters.get_counter("research",target),3,
			"Alterant modifies retrieved counter value")
	assert_eq(board.counters.get_counter("research",card),0,
			"Alterant not modified retrieved counter value when trigger is self")
	var type : String = target.properties["Type"]
	card.scripts = {"alterants": {"hand": [
			{"filter_task": "get_counter",
			"filter_counter_name": "research",
			"alteration": 3,
			"filter_state_trigger": [{
				"filter_properties": {"Type": type}
			}],},]}}
	assert_eq(board.counters.get_counter("research",target),3,
			"Alterant modifies retrieved counter value when filter matches")
	assert_eq(board.counters.get_counter("research",card),0,
			"Alterant not modified retrieved counter value when filter does not match")

func test_get_token_alterants():
	yield(table_move(target, Vector2(200,200)), "completed")
	target.tokens.mod_token("blood")
	target.tokens.mod_token("industry")
	var industry_token: Token = target.tokens.get_token("industry")
	var blood_token: Token = target.tokens.get_token("blood")
	card.scripts = {"alterants": {"hand": [
			{"filter_task": "get_token",
			"trigger": "another",
			"filter_token_name": "industry",
			"alteration": 1},
			{"filter_task": "get_token",
			"trigger": "self",
			"filter_token_name": "blood",
			"alteration": 2},]}}
	cfc.flush_cache()
	assert_eq(industry_token.count,2,
			"Token retrieved as specified amount + alterant")
	assert_eq(blood_token.count,1,
			"Token retrieved as specified amount + alterant")


func test_get_property_alterants():
	target.modify_property("Cost", 2)
	target.modify_property("Power", 2)
	card.modify_property("Cost", 2)
	card.scripts = {"alterants": {"hand": [
			{"filter_task": "get_property",
			"trigger": "another",
			"filter_property_name": "Cost",
			"alteration": 3},]}}
	assert_eq(target.get_property("Cost"),5,
			"Alterant modifies retrieved property value")
	assert_eq(target.get_property("Power"),2,
			"Alterant not modified different property")
	assert_eq(card.get_property("Cost"),2,
			"Alterant not modified retrieved counter value when trigger is self")

func test_properties_alterants():
	card.modify_property("Power", 0)
	card.modify_property("Cost",0)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "modify_properties",
			"trigger": "another",
			"filter_property_name": "Cost",
			"alteration": 1},
			{"filter_task": "mod_tokens",
			"trigger": "another",
			"filter_property_name": "Power",
			"alteration": 2},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "+1"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),2,
			"Cost altered correctly")
	assert_eq(card.get_property("Power"),0,
			"Cost altered correctly")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": 7}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),8,
			"Cost altered correctly")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "-1"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),8,
			"Cost altered correctly")

func test_properties_alterants_with_polarity():
	card.modify_property("Cost",0)
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "modify_properties",
			"trigger": "another",
			"filter_property_name": "Cost",
			"filter_count_difference": "increased",
			"alteration": 1},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "+1"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),2,
			"Cost altered correctly")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": 7}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),8,
			"Cost altered correctly")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "-1"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),7,
			"Cost altered correctly")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": 4}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),4,
			"Cost altered correctly")
	target.scripts = {"alterants": {"hand": [
			{"filter_task": "modify_properties",
			"trigger": "another",
			"filter_property_name": "Cost",
			"filter_count_difference": "decreased",
			"alteration": -1},]}}
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "-1"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),2,
			"Cost altered correctly")
