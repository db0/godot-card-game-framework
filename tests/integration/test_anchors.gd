extends "res://tests/UTcommon.gd"

const _PILE_SCENE_FILE = CFConst.PATH_CORE + "Pile.tscn"
const _PILE_SCENE = preload(_PILE_SCENE_FILE)
var cards := []
var deck2 : Pile


func before_each():
	setup_board()
	deck2 = autoqfree(_PILE_SCENE.instance())

func test_anchor_positioning_and_groups():
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	assert_almost_eq(deck.position, Vector2(0,474), Vector2(2,2),
			"Bottom left anchor placement works")
	assert_true("bottom" in deck.get_groups(), "bottom Position group assigned")
	assert_true("left" in deck.get_groups(), "left Position group assigned")
	assert_almost_eq(discard.position, Vector2(1124,474), Vector2(2,2),
			"Bottom right anchor placement works")
	assert_true("bottom" in discard.get_groups(), "bottom Position group assigned")
	assert_true("right" in discard.get_groups(), "right Position group assigned")
	assert_almost_eq(hand.position, Vector2(163.5,600), Vector2(2,2),
			"Bottom middle anchor placement works")
	assert_almost_eq(hand.control.rect_size, Vector2(960.5,240), Vector2(2,2),
			"Hand correct size not to overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(480.25,120), Vector2(2,2),
			"Hand collision shape correct size to not overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(480.25,120), Vector2(2,2),
			"Hand collision shape correct position to not overlap with piles")
	assert_true("bottom" in hand.get_groups(), "bottom Position group assigned")
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.TOP_LEFT
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(0,0), Vector2(2,2),
			"Top left anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	assert_true("left" in deck2.get_groups(), "left Position group assigned")
	deck2.placement = CardContainer.Anchors.TOP_RIGHT
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(1124,0), Vector2(2,2),
			"Top Right anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	assert_true("right" in deck2.get_groups(), "right Position group assigned")
	deck2.placement = CardContainer.Anchors.TOP_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(562,0), Vector2(2,2),
			"Top Middle anchor placement works")
	assert_true("top" in deck2.get_groups(), "top Position group assigned")
	deck2.placement = CardContainer.Anchors.RIGHT_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(1124,237), Vector2(2,2),
			"Right Middle anchor placement works")
	assert_true("right" in deck2.get_groups(), "right Position group assigned")
	deck2.placement = CardContainer.Anchors.LEFT_MIDDLE
	deck2.re_place()
	assert_almost_eq(deck2.position, Vector2(0,237), Vector2(2,2),
			"Left Middle anchor placement works")
	assert_true("left" in deck2.get_groups(), "left Position group assigned")

func test_overlap_shift_up():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_LEFT
	deck2.overlap_shift_direction = CFConst.OverlapShiftDirection.UP
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	assert_almost_eq(deck2.position, Vector2(0,213), Vector2(2,2),
			"overlapping deck2 shifted up")
	assert_almost_eq(deck.position, Vector2(0,474), Vector2(2,2),
			"OverlapShiftDirection == NONE allowed the deck to stay where it is")
	assert_almost_eq(hand.position, Vector2(163.5,600), Vector2(2,2),
			"Hand didn't shift when overlap was displaced upwards")
	assert_almost_eq(hand.control.rect_size, Vector2(960.5,240), Vector2(2,2),
			"Hand not shrunk when overlap was displaced upwards")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(480.25,120), Vector2(2,2),
			"Hand collision size not shrunk when overlap was displaced upwards")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(480.25,120), Vector2(2,2),
			"Hand collision position not shrunk when overlap was displaced upwards")

func test_overlap_shift_left():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_RIGHT
	deck2.overlap_shift_direction = CFConst.OverlapShiftDirection.LEFT
	deck2.re_place()
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	assert_almost_eq(deck2.position, Vector2(968,474), Vector2(2,2),
			"overlapping deck2 shifted left")
	assert_almost_eq(discard.position, Vector2(1124,474), Vector2(2,2),
			"OverlapShiftDirection == NONE allowed the discard to stay where it is")
	assert_almost_eq(hand.position, Vector2(163.5,600), Vector2(2,2),
			"Hand didn't shift when right containers shifted")
	assert_almost_eq(hand.control.rect_size, Vector2(804.5,240), Vector2(2,2),
			"Hand shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(402.25,120), Vector2(2,2),
			"Hand collision size shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(402.25,120), Vector2(2,2),
			"Hand collision position shrunk when overlap was displaced left")

func test_overlap_shift_right():
	board.add_child(deck2)
	deck2.placement = CardContainer.Anchors.BOTTOM_LEFT
	deck2.overlap_shift_direction = CFConst.OverlapShiftDirection.RIGHT
	deck2.re_place()
	for container in get_tree().get_nodes_in_group("card_containers"):
		container.re_place()
	assert_almost_eq(deck2.position, Vector2(163.5,474), Vector2(2,2),
			"overlapping deck2 shifted left")
	assert_almost_eq(deck.position, Vector2(0,474), Vector2(2,2),
			"OverlapShiftDirection == NONE allowed the discard to stay where it is")
	assert_almost_eq(hand.position, Vector2(312,600), Vector2(2,2),
			"Hand didn't shift when right containers shifted")
	assert_almost_eq(hand.control.rect_size, Vector2(804.5,240), Vector2(2,2),
			"Hand shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(402.25,120), Vector2(2,2),
			"Hand collision size shrunk when overlap was displaced left")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(402.25,120), Vector2(2,2),
			"Hand collision position shrunk when overlap was displaced left")

func test_changing_viewport_size():
	get_viewport().size = Vector2(1920, 1080)
	assert_almost_eq(deck.position, Vector2(0,834), Vector2(2,2),
			"Bottom left anchor placement works")
	assert_almost_eq(discard.position, Vector2(1764,834), Vector2(2,2),
			"Bottom right anchor placement works")
	assert_almost_eq(hand.position, Vector2(163.5,960), Vector2(2,2),
			"Bottom middle anchor placement works")
	assert_almost_eq(hand.control.rect_size, Vector2(1600.5,240), Vector2(2,2),
			"Hand correct size not to overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").shape.extents,
			Vector2(800.25,120), Vector2(2,2),
			"Hand collision shape correct size to not overlap with piles")
	assert_almost_eq(hand.get_node("CollisionShape2D").position,
			Vector2(800.25,120), Vector2(2,2),
			"Hand collision shape correct position to not overlap with piles")
	assert_true("bottom" in hand.get_groups(), "bottom Position group assigned")
	get_viewport().size = Vector2(1280, 720)
