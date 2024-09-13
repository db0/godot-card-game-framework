extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	await setup_main()
	cards = draw_test_cards(5)
	await yield_for(0.1)

func test_board_facedown():
	var card: Card
	card = cards[3]
	var card_front = card.get_node("Control/Front")
	var card_back = card.get_node("Control/Back")
	await table_move(card, Vector2(600,200))
	card.is_faceup = false
	await yield_to(card._flip_tween, "finished", 1)
	assert_false(card_front.visible,
			"Front should be invisible when card is turned face down")
	assert_almost_eq(card_front.scale.x, 0.0, 0.1,
			"Front should be scaled.x to 0 when card is turned face down")
	assert_almost_eq(card_front.position.x, card_front.size.x/2, 0.1,
			"Front position.x == size.x/2 when card is turned face down")
	assert_true(card_back.visible,
			"Back should be visible when card is turned face down")
	assert_almost_eq(card_back.scale.x, 1.0, 0.1,
			"Back should be scaled.x to 1 when card is turned face down")
	assert_almost_eq(card_back.position.x, 0.0, 0.1,
			"Back position.x == 0 when card is turned face down")
	card.is_faceup = true
	await yield_to(card._flip_tween, "finished", 1)
	await yield_to(card._flip_tween, "finished", 1)
	assert_true(card_front.visible,
			"Front should be visible when card is turned face up again")
	assert_almost_eq(card_front.scale.x, 1.0, 0.1,
			"ront should be scaled.x to 0 when card is turned face up again")
	assert_almost_eq(card_front.position.x, 0.0, 0.1,
			"Front position.x == 0 when card is turned face up again")
	assert_false(card_back.visible,
			"Back should be invisible when card is turned face up again")
	assert_almost_eq(card_back.scale.x, 0.0, 0.1,
			"Back should b scaled.x to 0 when card is turned face up again")
	assert_almost_eq(card_back.position.x, card_front.size.x/2, 0.1,
			"Back position.x == size.x/2 when card is turned face up again")

	await move_mouse(card.global_position)
	await yield_for(0.1) # Wait to allow dupe to be created
	#pre: for some reason _previously_focused_cards doesn't populate in this test
	var dupe: Card = main._previously_focused_cards[card]
	var dupe_front = dupe.get_node("Control/Front")
	var dupe_back = dupe.get_node("Control/Back")
	var view_button  = card.get_node("Control/ManipulationButtons/View")
	var viewed_icon  = card.card_back.viewed_node
	card.is_faceup = false
	await yield_to(card._flip_tween, "finished", 1)
	await yield_to(card._flip_tween, "finished", 1)
	assert_false(dupe_front.visible,
			"Dupe Front should be invisible when card is turned face down")
	assert_almost_eq(dupe_front.scale.x, 0.0, 0.1,
			"Dupe Front should be scaled.x to 0 when card is turned face down")
	assert_almost_eq(dupe_front.position.x, dupe_front.size.x/2, 0.1,
			"Dupe Front position.x == size.x/2 when card is turned face down")
	assert_true(dupe_back.visible,
			"Dupe Back should be visible when card is turned face down")
	assert_almost_eq(dupe_back.scale.x, 1.0, 0.1,
			"Dupe Back should be scaled.x to 1 when card is turned face down")
	assert_almost_eq(dupe_back.position.x, 0.0, 0.1,
			"Dupe Back position.x == 0 when card is turned face down")
	card.is_faceup = true
	await yield_to(card._flip_tween, "finished", 1)
	assert_false(view_button.visible,"View button should be invisible while card is face up")
	assert_true(dupe_front.visible,
			"Dupe Front should be visible when card is turned face up again")
	assert_almost_eq(dupe_front.scale.x, 1.0, 0.1,
			"Dupe Front should be scaled.x to 0 when card is turned face up again")
	assert_almost_eq(dupe_front.position.x, 0.0, 0.1,
			"Dupe Front position.x == 0 when card is turned face up again")
	assert_false(dupe_back.visible,
			"Dupe Back should be invisible when card is turned face up again")
	assert_almost_eq(dupe_back.scale.x, 0.0, 0.1,
			"Dupe Back should b scaled.x to 0 when card is turned face up again")
	assert_almost_eq(dupe_back.position.x, dupe_front.size.x/2, 0.1,
			"Dupe Back position.x == size.x/2 when card is turned face up again")

	assert_false(viewed_icon.visible,
			"View icon should be invisible after card is turned face up")
	card.is_faceup = false
	await yield_to(card._flip_tween, "finished", 1)
	assert_true(view_button.visible,
			"View button should be visible while card is face down")
	assert_eq(CFConst.ReturnCode.OK,card.set_is_viewed(false),
			"View function returns OK requesting false when card is_viewed == false while facedown")
	assert_eq(CFConst.ReturnCode.CHANGED,card.set_is_viewed(true),
			"View function returns Changed when requesting true first time with card facedown")
	assert_true(dupe_front.visible,
			"Dupe is visible after pressing view button while still hovering the card")
	assert_eq(CFConst.ReturnCode.OK,card.set_is_viewed(true),
			"View function returns OK when requesting true a second time with card facedown")
	assert_eq(CFConst.ReturnCode.FAILED,card.set_is_viewed(false),
			"View function returns FAILED requesting false when card is_viewed == true while facedown")
	assert_true(viewed_icon.visible,
			"View icon is visible while card is is_viewed()")

	await move_mouse(card.global_position - Vector2(0,100))
#	yield(yield_for(0.2), YIELD) # Wait to allow dupe to be destroyed
	await move_mouse(card.global_position)
#	yield(yield_for(0.2), YIELD) # Wait to allow dupe to be created
	dupe = main._previously_focused_cards[card]
	dupe_front = dupe.get_node("Control/Front")
	assert_true(dupe_front.visible,
			"Dupe is visible after moving mouse in and out to restart focus")

	card.is_faceup = true
	await yield_to(card._flip_tween, "finished", 1)
	assert_eq(CFConst.ReturnCode.FAILED,card.set_is_viewed(true),
			"View function returns FAILED when requesting true while card is faceup")
	assert_eq(CFConst.ReturnCode.OK,card.set_is_viewed(false),
			"View function returns OK when requesting false and is_viewed == false")

func test_off_board_facedown():
	var card: Card
	card = cards[0]
	var card_front = card.get_node("Control/Front")
	var card_back = card.get_node("Control/Back")
	card.is_faceup = false
	await yield_to(card._flip_tween, "finished", 1)
	assert_false(card_front.visible,
			"Front should be invisible when card is turned face down")
	assert_almost_eq(card_front.scale.x, 0.0, 0.1,
			"Front should be scaled.x to 0 when card is turned face down")
	assert_almost_eq(card_front.position.x, card_front.size.x/2, 0.1,
			"Front position.x == size.x/2 when card is turned face down")
	assert_true(card_back.visible,
			"Back should be visible when card is turned face down")
	assert_almost_eq(card_back.scale.x, 1.0, 0.1,
			"Back should be scaled.x to 1 when card is turned face down")
	assert_almost_eq(card_back.position.x, 0.0, 0.1,
			"Back position.x == 0 when card is turned face down")
	card.is_faceup = true
	await yield_to(card._flip_tween, "finished", 1)
	await yield_to(card._flip_tween, "finished", 1)
	assert_true(card_front.visible,
			"Front should be visible when card is turned face up again")
	assert_almost_eq(card_front.scale.x, 1.0, 0.1,
			"Front should be scaled.x to 0 when card is turned face up again")
	assert_almost_eq(card_front.position.x, 0.0, 0.1,
			"Front position.x == 0 when card is turned face up again")
	assert_false(card_back.visible,
			"Back should be invisible when card is turned face up again")
	assert_almost_eq(card_back.scale.x, 0.0, 0.1,
			"Back should b scaled.x to 0 when card is turned face up again")
	assert_almost_eq(card_back.position.x, card_front.size.x/2, 0.1,
			"Back position.x == size.x/2 when card is turned face up again")
