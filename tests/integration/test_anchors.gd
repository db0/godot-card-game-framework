extends "res://tests/UTcommon.gd"

const _PILE_SCENE_FILE = CFConst.PATH_CORE + "Pile.tscn"
const _PILE_SCENE = preload(_PILE_SCENE_FILE)
var cards := []
var deck2 : Pile


func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	deck2 = autoqfree(_PILE_SCENE.instance())

func test_anchor_positioning_and_groups():
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	assert_almost_eq(deck.position, Vector2(0,480), Vector2(5,5),
			"Bottom left anchor placement works")
	assert_true("bottom" in deck.get_groups(), "bottom Position group assigned")
	assert_true("left" in deck.get_groups(), "left Position group assigned")
	assert_almost_eq(discard.position, Vector2(1130,480), Vector2(5,5),
			"Bottom right anchor placement works")
	assert_true("bottom" in discard.get_groups(), "bottom Position group assigned")
	assert_true("right" in discard.get_groups(), "right Position group assigned")
	yield(yield_for(0.1), YIELD)
	assert_almost_eq(hand.position, Vector2(160.5,600), Vector2(5,5),
			"Bottom middle anchor placement works")
	assert_almost_eq(hand.control.rect_size, Vector2(966.5,240), Vector2(5,5),
			"Hand correct size not to overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(483.25,120), Vector2(5,5),
			"Hand collision shape correct size to not overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(483.25,120), Vector2(5,5),
			"Hand collision shape correct position to not overlap with piles")
	assert_true("bottom" in hand.get_groups(), "bottom Position group assigned")
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.TOP_LEFT
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(0,0), Vector2(5,5),
			"Top left anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	assert_true("left" in deck2.get_groups(), "left Position group assigned")
	deck2.placement = CardContainer.Anchors.TOP_RIGHT
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(1127,0), Vector2(5,5),
			"Top Right anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	assert_true("right" in deck2.get_groups(), "right Position group assigned")
	deck2.placement = CardContainer.Anchors.TOP_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(562,0), Vector2(5,5),
			"Top Middle anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	deck2.placement = CardContainer.Anchors.RIGHT_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(1127,237), Vector2(5,5),
			"Right Middle anchor placement works")
	assert_true("right" in deck2.get_groups(), "right Position group assigned")
	deck2.placement = CardContainer.Anchors.LEFT_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(0,237), Vector2(5,5),
			"Left Middle anchor placement works")
	assert_true("left" in deck2.get_groups(), "left Position group assigned")

func test_overlap_shift_up():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_LEFT
	deck2.overlap_shift_direction = CFInt.OverlapShiftDirection.UP
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	yield(yield_for(0.1), YIELD)
	assert_almost_eq(deck2.position, Vector2(0,219), Vector2(5,5),
			"overlapping deck2 shifted up")
	assert_almost_eq(deck.position, Vector2(0,480), Vector2(5,5),
			"OverlapShiftDirection == NONE allowed the deck to stay where it is")
	assert_almost_eq(hand.position, Vector2(160.5,600), Vector2(5,5),
			"Hand didn't shift when overlap was displaced upwards")
	assert_almost_eq(hand.control.rect_size, Vector2(966.5,240), Vector2(5,5),
			"Hand not shrunk when overlap was displaced upwards")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(483.25,120), Vector2(5,5),
			"Hand collision size not shrunk when overlap was displaced upwards")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(483.25,120), Vector2(5,5),
			"Hand collision position not shrunk when overlap was displaced upwards")

func test_overlap_shift_left():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_RIGHT
	deck2.overlap_shift_direction = CFInt.OverlapShiftDirection.LEFT
	deck2.re_place()
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	yield(yield_for(0.1), YIELD)
	assert_almost_eq(deck2.position, Vector2(977,480), Vector2(5,5),
			"overlapping deck2 shifted left")
	assert_almost_eq(discard.position, Vector2(1130,480), Vector2(5,5),
			"OverlapShiftDirection == NONE allowed the discard to stay where it is")
	assert_almost_eq(hand.position, Vector2(160.5,600), Vector2(5,5),
			"Hand didn't shift when right containers shifted")
	assert_almost_eq(hand.control.rect_size, Vector2(813.5,240), Vector2(5,5),
			"Hand shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(406.25,120), Vector2(5,5),
			"Hand collision size shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(406.25,120), Vector2(5,5),
			"Hand collision position shrunk when overlap was displaced left")

func test_overlap_shift_right():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_LEFT
	deck2.overlap_shift_direction = CFInt.OverlapShiftDirection.RIGHT
	deck2.re_place()
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	yield(yield_for(0.1), YIELD)
	assert_almost_eq(deck2.position, Vector2(160.5,480), Vector2(5,5),
			"overlapping deck2 shifted left")
	assert_almost_eq(deck.position, Vector2(0,480), Vector2(5,5),
			"OverlapShiftDirection == NONE allowed the discard to stay where it is")
	assert_almost_eq(hand.position, Vector2(306,600), Vector2(5,5),
			"Hand didn't shift when right containers shifted")
	assert_almost_eq(hand.control.rect_size, Vector2(813.5,240), Vector2(5,5),
			"Hand shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(406.25,120), Vector2(5,5),
			"Hand collision size shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(406.25,120), Vector2(5,5),
			"Hand collision position shrunk when overlap was displaced left")

func test_changing_viewport_size():
	get_viewport().size = Vector2(1920, 1080)
	yield(yield_for(0.1), YIELD)
	assert_almost_eq(deck.position, Vector2(0,840), Vector2(5,5),
			"Bottom left anchor placement works")
	assert_almost_eq(discard.position, Vector2(1770,840), Vector2(5,5),
			"Bottom right anchor placement works")
	assert_almost_eq(hand.position, Vector2(160.5,960), Vector2(5,5),
			"Bottom middle anchor placement works")
	assert_almost_eq(hand.control.rect_size, Vector2(1606.5,240), Vector2(5,5),
			"Hand correct size not to overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(803.25,120), Vector2(5,5),
			"Hand collision shape correct size to not overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(803.25,120), Vector2(5,5),
			"Hand collision shape correct position to not overlap with piles")
	assert_true("bottom" in hand.get_groups(), "bottom Position group assigned")
	get_viewport().size = Vector2(1280, 720)
