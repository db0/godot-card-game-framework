extends "res://tests/UTcommon.gd"

class TestDrawMoreCardsThanPileMax:
	extends "res://tests/ScEng_common.gd"

	func test_draw_more_cards_than_pile_max():
		target = deck.get_last_card()
		pending("Test good execution of nested tasks")
		pending("Test failing cost in nested cost task aborts parent script")
