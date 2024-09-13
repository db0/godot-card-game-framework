extends "res://tests/UTcommon.gd"

var cards := []
var grid : BoardPlacementGrid

func before_each():
	await setup_board()
	board.get_node("BoardPlacementGrid").visible = true
	cards = draw_test_cards(5)
	await yield_for(0.1)
	grid = board.get_node("BoardPlacementGrid")
	grid.position = Vector2(500,450)
	board.get_node("BoardPlacementGrid").visible = true

func test_highlight_priority():
	var card : Card = cards[0]
	await table_move(cards[2], Vector2(550,500))
	card.attachment_mode = Card.AttachmentMode.ATTACH_BEHIND
	await drag_card(card, Vector2(600,500))
	assert_null(grid.get_highlighted_slot(),
		"No slot highlighted when potential host highlighted")
	await move_mouse(Vector2(600,600))
	assert_null(grid.get_highlighted_slot(),
		"No slot highlighted when potential host highlighted")
	assert_false(cards[2].highlight.visible,
		"Potential host not highlighted when mouse over CardContainer")
	assert_true(hand.highlight.visible,
		"Hand higlighted for placement")
	await move_mouse(Vector2(700,600))
	assert_null(grid.get_highlighted_slot(),
		"No slot highlighted when potential host highlighted")
	assert_true(hand.highlight.visible,
		"Hand higlighted for placement")
	await move_mouse(Vector2(700,500))
	assert_not_null(grid.get_highlighted_slot(),
		"Slot highlighted when potential host highlighted")

func test_specific_grid_highlight():
	var card : Card = cards[0]
	card.board_placement = Card.BoardPlacement.SPECIFIC_GRID
	card.mandatory_grid_name = "GUT Grid"
	await drag_card(card, Vector2(700,500))
	assert_null(grid.get_highlighted_slot(),
		"No slot highlighted on wrong name grid")

func test_no_board_placement_highlight():
	var card : Card = cards[0]
	card.board_placement = Card.BoardPlacement.NONE
	await drag_card(card, Vector2(700,500))
	assert_null(grid.get_highlighted_slot(),
		"No slot highlighted when board placement not allowed")
