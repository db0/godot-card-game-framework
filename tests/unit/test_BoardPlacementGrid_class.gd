extends "res://tests/UTcommon.gd"

var cards := []
var grid: BoardPlacementGrid

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	grid = board.get_node("BoardPlacementGrid")

func test_get_all_slots():
	var all_slots = grid.get_all_slots()
	for slot in all_slots:
		assert_is(slot, BoardPlacementSlot)

func test_get_slot_count():
	assert_eq(grid.get_slot_count(), 4)

func test_get_highlighted_slot():
	assert_null(grid.get_highlighted_slot(),
			'Grid starts with no slot highlighted')
	grid.get_slot(0).get_node("Highlight").visible = true
	assert_eq(grid.get_highlighted_slot(),grid.get_slot(0),
			'Returns highlighted slot')

func test_get_slot():
	assert_eq(grid.get_child(0).get_child(0),grid.get_slot(0),
			'Returns correct slot index')
	assert_eq(grid.get_child(0).get_child(2),grid.get_slot(2),
			'Returns correct slot index')

func test_add_slot():
	var old_count = grid.get_slot_count()
	var _new_slot = grid.add_slot()
	assert_lt(old_count,grid.get_slot_count(),
			'New slot added')
