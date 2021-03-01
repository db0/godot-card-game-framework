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


# Checks that custom scripts fire correctly
func test_custom_script():
	card = cards[2]
	# Custom scripts have to be predefined in code
	# So not possible to specify them as runtime scripts
	card.execute_scripts()
	yield(yield_for(0.1), YIELD)
	assert_freed(card, "Test Card 2")
	card = cards[1]
	target = cards[3]
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_for(0.3), YIELD)
	assert_freed(target, "Test Card 1")


func test_rotate_card():
	card.scripts = {"manual": {"board": [
			{"name": "rotate_card",
			"subject": "self",
			"degrees": 90}]}}
	yield(table_move(card, Vector2(100,200)), "completed")
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(card.card_rotation, 90,
			"Card should be rotated 90 degrees")


func test_flip_card():
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": false}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_false(target.is_faceup,
			"Target should be face-down")
	card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"set_faceup": true}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
	assert_true(target.is_faceup,
			"Target should be face-up again")

func test_view_card():
	target.is_faceup = false
	card.scripts = {"manual": {"hand": [
				{"name": "view_card",
				"subject": "target"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	assert_true(target.is_viewed,
			"Target should be viewed")
	target = cfc.NMAP.deck.get_top_card()
	card.scripts = {"manual": {"hand": [
				{"name": "view_card",
				"src_container":  cfc.NMAP.deck,
				"subject_index": "top",
				"subject": "index"}]}}
	card.execute_scripts()
	assert_true(target.is_viewed,
			"Target should be viewed")


func test_move_card_to_container():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "self",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.discard,card.get_parent(),
			"Card should have moved to discard pile")
	card = cards[1]
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "self",
			"dest_index": 5,
			"dest_container":  cfc.NMAP.deck}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.deck,card.get_parent(),
			"Card should have moved to deck")
	assert_eq(5,card.get_my_card_index(),
			"Card should have moved to index 5")


func test_move_card_hand_to_board():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "self",
			"board_position":  Vector2(100,100)}]}}
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.board,card.get_parent(),
			"Card should have moved to board")
	assert_eq(Vector2(100,100),card.global_position,
			"Card should have moved to specified position")


func test_move_card_cont_to_cont():
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": 5,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(cfc.NMAP.discard,target.get_parent(),
			"Card should have moved to discard pile")
	target = cfc.NMAP.deck.get_card(3)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": 3,
			"dest_index": 1,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_eq(cfc.NMAP.discard,target.get_parent(),
			"Card should have moved to discard")
	assert_eq(1,target.get_my_card_index(),
			"Card should have moved to index 1")


func test_move_card_cont_to_board():
	yield(yield_for(0.2), YIELD)
	target = cfc.NMAP.deck.get_card(5)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_index": 5,
			"src_container":  cfc.NMAP.deck,
			"board_position":  Vector2(1000,200)}]}}
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_for(0.2), YIELD)
	assert_almost_eq(Vector2(1000,200),target.global_position, Vector2(5,5),
			"Card should have moved to specified board position")
	target = cfc.NMAP.deck.get_card(0)
	var target2 = cfc.NMAP.deck.get_card(1)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_board",
			"subject": "index",
			"subject_count": 4,
			"subject_index": "bottom",
			"src_container":  cfc.NMAP.deck,
			"grid_name":  "BoardPlacementGrid"}]}}
	board.get_node("BoardPlacementGrid").visible = true
	yield(execute_with_yield(card), "completed")
	assert_not_null(target._placement_slot,
			"Card should have moved to a grid slot")
	assert_not_null(target2._placement_slot,
			"Card should have moved to a grid slot")
	if target._placement_slot:
		assert_eq(target._placement_slot.get_grid_name(), "BoardPlacementGrid",
				"Card placed in the correct grid")
		assert_ne(target._placement_slot, target2._placement_slot,
				"Cards not placed in the same slot")


func test_mod_tokens():
	target.scripts = {"manual": {"hand": [
			{"name": "mod_tokens",
			"subject": "self",
			"modification": 5,
			"token_name":  "industry"}]}}
	target.execute_scripts()
	var industry_token: Token = target.tokens.get_token("industry")
	assert_eq(5,industry_token.count,"Token increased by specified amount")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_tokens",
			"subject": "target",
			"modification": 2,
			"set_to_mod": true,
			"token_name":  "industry"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	# My scripts are slower now
	yield(yield_for(0.2), YIELD)
	assert_eq(2,industry_token.count,"Token set to specified amount")


func test_spawn_card():
	target.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"card_name": "Spawn Card",
			"object_count": 3,
			"board_position":  Vector2(500,200)}]}}
	target.execute_scripts()
	assert_eq(3,board.get_card_count(),
		"Card spawned on board")
	card = board.get_card(0)
	assert_eq("res://src/custom/cards/Token.tscn",card.filename,
		"Card of the correct scene spawned")
	assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
		"Spawned card left in correct state")
	assert_almost_eq(Vector2(500,200),card.position,Vector2(2,2),
		"Card spawned in correct location")
	var offsetx = CFConst.CARD_SIZE.x * CFConst.PLAY_AREA_SCALE.x
	assert_almost_eq(Vector2(500 + offsetx * 2,200),
			board.get_card(2).position,Vector2(2,2),
			"Third Card spawned in correct location")
	target.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"card_name": "Spawn Card",
			"object_count": 10,
			"grid_name":  "BoardPlacementGrid"}]}}
	target.execute_scripts()
	# Give time to the card to instance
	yield(yield_for(0.4), YIELD)
	assert_eq(7,board.get_card_count(),
		"5 Card spawned on grid")
	if board.get_card_count() > 1:
		card = board.get_card(3)
		assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
			"Spawned card left in correct state")
		assert_not_null(card._placement_slot,
				"Card should have moved to a grid slot")


func test_shuffle_container():
	card.scripts = {"manual": {"hand": [
			{"name": "shuffle_container",
			"dest_container":  cfc.NMAP.hand}]}}
	var rng_threshold: int = 0
	var prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	card.execute_scripts()
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if prev_index == card.get_my_card_index():
		rng_threshold += 1
	prev_index = card.get_my_card_index()
	assert_gt(3,rng_threshold,
		"Card should not fall in he same spot too many times")


func test_attach_to_card():
	yield(table_move(target, Vector2(500,400)), "completed")
	card.scripts = {"manual": {"hand": [
			{"name": "attach_to_card",
			"subject": "target"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(card.current_host_card,target,
			"Card has been hosted on the target")


func test_host_card():
	yield(table_move(card, Vector2(500,400)), "completed")
	card.scripts = {"manual": {"board": [
			{"name": "host_card",
			"subject": "target"}]}}
	card.execute_scripts()
	yield(target_card(card,target), "completed")
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(target.current_host_card,card,
			"target has been hosted on the card")


func test_modify_properties():
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Name": "GUT Test", "Type": "Orange"}}]}}
	card.execute_scripts()
	assert_eq(card.card_name,"GUT Test",
			"Card name should be changed")
	assert_eq(card.get_property("Type"),"Orange",
			"Card type should be changed")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "+5"}}]}}
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),5,
			"Card cost increased")
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "-2"}}]}}
	card.scripts = {"manual": {"hand": [
			{"name": "modify_properties",
			"subject": "self",
			"set_properties": {"Cost": "-2"}}]}}
	card.execute_scripts()
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),1,
			"Card cost decreased")
	card.execute_scripts()
	assert_eq(card.get_property("Cost"),0,
			"Card cost not below 0 ")


func test_create_grid():
	card.scripts = {"manual": {"hand": [
			{"name": "add_grid",
			"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
			"object_count": 2,
			"board_position":  Vector2(50,50)}]}}
	yield(execute_with_yield(card), "completed")
	var grids: Array = get_tree().get_nodes_in_group("placement_grid")
	assert_eq(grids.size(), 3, "All grids were created")
	card.scripts = {"manual": {"hand": [
			{"name": "add_grid",
			"scene_path": "res://src/custom/CGFPlacementGridDemo.tscn",
			"grid_name": "GUT Grid",
			"object_count": 3,
			"board_position":  Vector2(600,50)}]}}
	yield(execute_with_yield(card), "completed")
	var gut_grids := []
	for g in get_tree().get_nodes_in_group("placement_grid"):
		if not g in grids:
			gut_grids.append(g)
	for grid in gut_grids:
		assert_eq(grid.name_label.text, "GUT Grid",
				"Created grid has correct label")

func test_mod_counter():
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 5,
			"counter_name":  "research"}]}}
	card.execute_scripts()
	assert_eq(5,board.counters.get_counter("research"),
			"Counter increased by specified amount")
	card.scripts = {"manual": {"hand": [
			{"name": "mod_counter",
			"modification": 2,
			"set_to_mod": true,
			"counter_name": "credits"}]}}
	card.execute_scripts()
	assert_eq(2,board.counters.get_counter("credits"),
			"Counter set to the specified amount")

func test_draw_more_cards_than_pile_max():
	target = deck.get_last_card()
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": "top",
			"subject_count": 50,
			"is_cost": true,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_eq(target.get_parent(),deck,
			"Card is not moved because more than max requested as cost")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_index": "top",
			"subject_count": 50,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_eq(target.get_parent(),discard,
			"Card is moved even though more than requested because it not cost")
