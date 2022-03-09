extends "res://tests/UTcommon.gd"

class TestBoardseekWithSubjectCount:
	extends "res://tests/ScEng_common.gd"

	func test_boardseek_with_subject_count():
		for iter in range(5):
			yield(table_move(deck.get_top_card(), Vector2(150*iter,200)), "completed")
		target = board.get_card(0)
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "boardseek",
				"dest_container": "discard"}]}}
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
				"dest_container": "discard"}]}}
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
				"dest_container": "discard"}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(5,discard.get_card_count(),
				"Rest cards in table should have been discarded")

class TestTutorWithSubjectCount:
	extends "res://tests/ScEng_common.gd"

	func test_tutor_with_subject_count():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "tutor",
				"src_container": "deck",
				"dest_container": "discard",
				"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}]}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(1,discard.get_card_count(),
				"tutor defaults to subject_count 1")
		for c in discard.get_all_cards():
			assert_eq("Blue", c.properties.Type,
				"Tutor correctly discarded only the Blue cards")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "tutor",
				"src_container": "deck",
				"dest_container": "discard",
				"subject_count": 2,
				"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}]}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(3,discard.get_card_count(),
				"2 cards in should have been tutored")
		for c in discard.get_all_cards():
			assert_eq("Blue", c.properties.Type,
				"Tutor correctly discarded only the Blue cards")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "tutor",
				"src_container": "deck",
				"dest_container": "discard",
				"subject_count": "all",
				"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}]}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		for c in deck.get_all_cards():
			assert_ne("Blue", c.properties.Type,
				"Tutor correctly discarded all Blue cards")


class TestIndexWithSubjectCount:
	extends "res://tests/ScEng_common.gd"

	func test_index_with_subject_count_from_top():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "top",
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_top_card()
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(1,discard.get_card_count(),
				"index defaults to subject_count 1")
		assert_eq(discard,target.get_parent(), "bottom card should be in discard")

		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "top",
				"subject_count": 5,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_top_card()
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(6,discard.get_card_count(),
				"5 cards in should have been index sought")
		assert_eq(discard,target.get_parent(), "bottom card should be in discard")

		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "top",
				"subject_count": "all",
				"src_container": "deck",
				"dest_container": "discard"}]}}
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
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "bottom",
				"subject_count": 5,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_bottom_card()
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(5,discard.get_card_count(),
				"5 cards in should have been index sought")
		assert_eq(discard,target.get_parent(), "bottom card should be in discard")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": "bottom",
				"subject_count": "all",
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_bottom_card()
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(0,deck.get_card_count(),
				"all cards should be discarded")
		assert_eq(discard,target.get_parent(), "bottom card should be in discard")

	func test_index_with_subject_count_from_index():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": 5,
				"subject_count": 5,
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_card(5)
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(discard,target.get_parent(), "target card should be in discard")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_index": 5,
				"subject_count": "all",
				"src_container": "deck",
				"dest_container": "discard"}]}}
		target = deck.get_card(5)
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(5,deck.get_card_count(),
				"5 cards in should have been left in deck")


