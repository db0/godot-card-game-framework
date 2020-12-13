extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
	cards = draw_test_cards(2)
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[1]


func test_boardseek_with_subject_count():
	for iter in range(5):
		yield(table_move(deck.get_top_card(), Vector2(150*iter,200)), "completed")
	target = board.get_card(0)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "boardseek",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(1,discard.get_card_count(),
			"boarseek defaults to subject_count 1")
	target = board.get_card(0)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "boardseek",
			"subject_count": 2,
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(3,discard.get_card_count(),
			"2 cards in table should have been discarded")
	target = board.get_card(0)
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "boardseek",
			"subject_count": "all",
			"dest_container":  cfc.NMAP.discard}]}}
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(5,discard.get_card_count(),
			"Rest cards in table should have been discarded")


func test_tutor_with_subject_count():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard,
			"filter_properties_tutor": {"Type": "Blue"}}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(1,discard.get_card_count(),
			"tutor defaults to subject_count 1")
	for c in discard.get_all_cards():
		assert_eq("Blue", c.properties.Type,
			"Tutor correctly discarded only the Blue cards")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard,
			"subject_count": 2,
			"filter_properties_tutor": {"Type": "Blue"}}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(3,discard.get_card_count(),
			"2 cards in should have been tutored")
	for c in discard.get_all_cards():
		assert_eq("Blue", c.properties.Type,
			"Tutor correctly discarded only the Blue cards")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "tutor",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard,
			"subject_count": "all",
			"filter_properties_tutor": {"Type": "Blue"}}]}}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	for c in deck.get_all_cards():
		assert_ne("Blue", c.properties.Type,
			"Tutor correctly discarded all Blue cards")


func test_index_with_subject_count_from_top():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": "top",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_top_card()
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(1,discard.get_card_count(),
			"index defaults to subject_count 1")
	assert_eq(discard,target.get_parent(), "bottom card should be in discard")

	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": "top",
			"subject_count": 5,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_top_card()
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(6,discard.get_card_count(),
			"5 cards in should have been index sought")
	assert_eq(discard,target.get_parent(), "bottom card should be in discard")

	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": "top",
			"subject_count": "all",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_top_card()
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(0,deck.get_card_count(),
			"all cards should be discarded")
	assert_eq(discard,target.get_parent(), "bottom card should be in discard")
	# Making sure trying to draw more cards than the deck doesn't crash
	card.execute_scripts()


func test_index_with_subject_count_from_bottom():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": "bottom",
			"subject_count": 5,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_bottom_card()
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(5,discard.get_card_count(),
			"5 cards in should have been index sought")
	assert_eq(discard,target.get_parent(), "bottom card should be in discard")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": "bottom",
			"subject_count": "all",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_bottom_card()
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(0,deck.get_card_count(),
			"all cards should be discarded")
	assert_eq(discard,target.get_parent(), "bottom card should be in discard")

func test_index_with_subject_count_from_index():
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": 5,
			"subject_count": 5,
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_card(5)
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(discard,target.get_parent(), "target card should be in discard")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_cont_to_cont",
			"subject": "index",
			"subject_index": 5,
			"subject_count": "all",
			"src_container":  cfc.NMAP.deck,
			"dest_container":  cfc.NMAP.discard}]}}
	target = deck.get_card(5)
	card.execute_scripts()
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
	assert_eq(5,deck.get_card_count(),
			"5 cards in should have been left in deck")


#func test_move_card_to_board():
#	card.scripts = {"manual": {"hand": [
#			{"name": "move_card_to_board",
#			"subject": "self",
#			"board_position":  Vector2(100,100)}]}}
#	card.execute_scripts()
#	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
#	assert_eq(cfc.NMAP.board,card.get_parent(),
#			"Card should have moved to board")
#	assert_eq(Vector2(100,100),card.global_position,
#			"Card should have moved to specified position")
#
#
#func test_move_card_cont_to_cont():
#	target = cfc.NMAP.deck.get_card(5)
#	card.scripts = {"manual": {"hand": [
#			{"name": "move_card_cont_to_cont",
#			"subject": "index",
#			"subject_index": 5,
#			"src_container":  cfc.NMAP.deck,
#			"dest_container":  cfc.NMAP.discard}]}}
#	card.execute_scripts()
#	yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
#	assert_eq(cfc.NMAP.discard,target.get_parent(),
#			"Card should have moved to discard pile")
#	target = cfc.NMAP.deck.get_card(3)
#	card.scripts = {"manual": {"hand": [
#			{"name": "move_card_cont_to_cont",
#			"subject": "index",
#			"subject_index": 3,
#			"dest_index": 1,
#			"src_container":  cfc.NMAP.deck,
#			"dest_container":  cfc.NMAP.discard}]}}
#	card.execute_scripts()
#	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
#	assert_eq(cfc.NMAP.discard,target.get_parent(),
#			"Card should have moved to discard")
#	assert_eq(1,target.get_my_card_index(),
#			"Card should have moved to index 1")
#
#
#func test_move_card_cont_to_board():
#	target = cfc.NMAP.deck.get_card(5)
#	card.scripts = {"manual": {"hand": [
#			{"name": "move_card_cont_to_board",
#			"subject": "index",
#			"subject_index": 5,
#			"src_container":  cfc.NMAP.deck,
#			"board_position":  Vector2(1000,200)}]}}
#	card.execute_scripts()
#	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
#	assert_eq(Vector2(1000,200),target.global_position,
#			"Card should have moved to specified board position")
#
#
#func test_mod_tokens():
#	target.scripts = {"manual": {"hand": [
#			{"name": "mod_tokens",
#			"subject": "self",
#			"modification": 5,
#			"token_name":  "industry"}]}}
#	target.execute_scripts()
#	var industry_token: Token = target.tokens.get_token("industry")
#	assert_eq(5,industry_token.count,"Token increased by specified amount")
#	card.scripts = {"manual": {"hand": [
#			{"name": "mod_tokens",
#			"subject": "target",
#			"modification": 2,
#			"set_to_mod": true,
#			"token_name":  "industry"}]}}
#	card.execute_scripts()
#	yield(target_card(card,target), "completed")
#	# My scripts are slower now
#	yield(yield_for(0.2), YIELD)
#	assert_eq(2,industry_token.count,"Token set to specified amount")
#
#
#func test_spawn_card():
#	target.scripts = {"manual": {"hand": [
#			{"name": "spawn_card",
#			"card_scene": "res://src/core/CardTemplate.tscn",
#			"board_position":  Vector2(500,200)}]}}
#	target.execute_scripts()
#	assert_eq(1,cfc.NMAP.board.get_card_count(),
#		"Card spawned on board")
#	card = cfc.NMAP.board.get_card(0)
#	assert_eq("res://src/core/CardTemplate.tscn",card.filename,
#		"Card of the correct scene spawned")
#	assert_eq(Card.CardState.ON_PLAY_BOARD,card.state,
#		"Spawned card left in correct state")


