extends "res://tests/UTcommon.gd"

var cards := []


func before_each():
	setup_board()
	cards = draw_test_cards(5)
	board.get_node("EnableAttach").pressed = true
	yield(yield_for(1), YIELD)


func test_attaching_and_switching_parent():
	var card : Card
	var card_prev_pos : Vector2
	var exhost_attachments: Array

	yield(drag_drop(cards[0],Vector2(300,300)), 'completed')
	card = cards[1]
	yield(drag_card(card, Vector2(310,310)), "completed")
	assert_true(cards[0].get_node('Control/FocusHighlight').visible,
			"Card hovering over another with attachment flag on, highlights it")
	assert_eq(cards[0].get_node('Control/FocusHighlight').modulate,
			cfc.HOST_HOVER_COLOUR,
			"Hovered host has the right colour highlight")
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card.global_position,cards[0].global_position
			+ Vector2(0,1)
			* card.get_node('Control').rect_size.y
			* cfc.ATTACHMENT_OFFSET, Vector2(2,2),
			"Card dragged in correct global position")
	assert_eq(card.current_host_card,cards[0],
			"Attached card has its parent in the current_host_card var")
	assert_eq(card,cards[0].attachments[0],
			"Card with hosted card has its children attachments array")
	assert_eq(1,len(cards[0].attachments),
			"Parent attachments array is the right size")
	assert_eq(cards[0].get_node('Control/FocusHighlight').modulate, Color(1,1,1),
			"Attaching card turns attach highlights off")

	card = cards[2]
	yield(drag_drop(card,Vector2(310,310)), 'completed')
	assert_almost_eq(card.global_position,cards[0].global_position
			+ Vector2(0,2)
			* card.get_node('Control').rect_size.y
			* cfc.ATTACHMENT_OFFSET, Vector2(2,2),
			"Multiple attached card are placed in the right position in regards to their parent")

	card = cards[3]
	yield(drag_drop(card,Vector2(310,310)), 'completed')
	assert_almost_eq(card.global_position,cards[0].global_position
			+ Vector2(0,3)
			* card.get_node('Control').rect_size.y
			* cfc.ATTACHMENT_OFFSET, Vector2(2,2),
			"Multiple attached card are placed in the right position in regards to their parent")
	assert_eq(3,len(cards[0].attachments),
			"Parent attachments array is the right size")
	card_prev_pos = card.global_position

	card = cards[0]
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(700,100),card.global_position)
	yield(yield_for(0.2), YIELD)
	assert_almost_ne(card_prev_pos,cards[3].global_position, Vector2(2,2),
			"Card drag also drags attachments")
	yield(yield_for(0.4), YIELD)
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_for(0.3), YIELD)
	assert_almost_ne(card_prev_pos,cards[3].global_position, Vector2(2,2),
			"Card drop also drops attachments in the right position")
	assert_almost_eq(cards[3].global_position,card.global_position
			+ Vector2(0,3)
			* card.get_node('Control').rect_size.y
			* cfc.ATTACHMENT_OFFSET, Vector2(2,2),
			"After attachment dragged, drop is placed correctly according to parent")
	yield(drag_card(card, Vector2(100,100)), "completed")
	for c in card.attachments:
		assert_false(c.get_node('Control/FocusHighlight').visible,
		"No card has potential_host highlighted when their parent is moving onto them")
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_null(card.current_host_card,
			"Card cannot be hosted in its own attachments")


	card = cards[1]
	card_prev_pos = card.global_position
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(700,100),card.global_position)
	yield(yield_for(0.2), YIELD)
	assert_almost_ne(card_prev_pos,card.global_position, Vector2(2,2),
			"Dragging an attached card is allowed")
	yield(yield_for(0.4), YIELD)
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card_prev_pos,card.global_position, Vector2(2,2),
			"After dropping an attached card, it returns to the parent host")
	yield(drag_drop(card,Vector2(400,500)), 'completed')
	assert_null(card.current_host_card,
			"Attachment clears out correctly when removed from table")
	assert_eq(2,len(cards[0].attachments),
			"Attachment clears out correctly when removed from table")
	assert_almost_eq(cards[3].global_position,cards[0].global_position
			+ Vector2(0,2) * card.get_node('Control').rect_size.y
			* cfc.ATTACHMENT_OFFSET, Vector2(2,2),
			"Removing an attachment reorganizes other attachments")

	card = cards[4]
	yield(drag_drop(card,Vector2(610,230)), 'completed')

	card = cards[3]
	yield(drag_drop(card,Vector2(630,230)), 'completed')
	assert_eq(card.current_host_card,cards[4],
			"Attached card can attach to another and clears out previous attachments")
	assert_eq(card,cards[4].attachments[0],
			"Reattached card is added to new host correctly")
	assert_false(card in cards[0].attachments,
			"Reattached card is removed from old host correctly")
	assert_eq(1,len(cards[4].attachments),
			"New host's attachments array is the right size")
	assert_eq(1,len(cards[0].attachments),
			"Old host's attachments array is the right size")

	card = cards[0]
	exhost_attachments = card.attachments.duplicate()
	yield(drag_drop(card,Vector2(630,230)), 'completed')
	assert_eq(card.current_host_card,cards[4],
			"Previous host attached itself properly")
	assert_eq(0,len(card.attachments),
			"Ex-host's attachments array cleared")
	assert_eq(3,len(cards[4].attachments),
			"New host's attachments array has hosted all old ex-host's cards")
	for c in exhost_attachments:
		assert_true(c in cards[4].attachments,
				"All old attachments were correctly migrated to new host")

	card = cards[4]
	exhost_attachments = card.attachments.duplicate()
	yield(drag_drop(card,cfc.NMAP.deck.position), 'completed')
	yield(yield_for(1), YIELD) # Wait to allow dragging to start
	assert_eq(0,len(card.attachments),
			"Card leaving the table clears out attachment variables in it")
	for c in exhost_attachments:
		assert_null(c.current_host_card,
				"Attachment of a host that left play clears out correctly")
		assert_eq(cfc.NMAP.deck,c.get_parent(),
				"Attachment of a host that left play follows it to the same target")


func test_multi_host_hover():
	var card : Card

	board.get_node("EnableAttach").pressed = false

	card = cards[0]
	yield(drag_drop(card,Vector2(100,100)), 'completed')

	card = cards[1]
	yield(drag_drop(card,Vector2(200,100)), 'completed')

	card = cards[2]
	yield(drag_drop(card,Vector2(150,100)), 'completed')

	board.get_node("EnableAttach").pressed = true

	card = cards[3]
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(150,100),card.global_position,10)
	yield(yield_for(0.3), YIELD)
	assert_true(cards[2].get_node('Control/FocusHighlight').visible,
			"Card hovering over two or more with attachment flag on, highlights only the top one")
	board._UT_interpolate_mouse_move(Vector2(300,100),card.global_position,10)
	yield(yield_for(0.3), YIELD)
	assert_false(cards[2].get_node('Control/FocusHighlight').visible,
			"Card leaving the hovering of a card, turns attach highlights off")
	assert_true(cards[1].get_node('Control/FocusHighlight').visible,
			"Potential host highlight changes as it changes hover areas")
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
