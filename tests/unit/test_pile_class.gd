extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")

func test_get_card_methods():
	var pile : Pile = cfc.NMAP.deck
	# The Panel is always put to the bottom with code. Therefore the third child node is always a card
	assert_eq(pile.get_child(5),pile.get_bottom_card(),
			'get_top_card() returns top card')
	# Likewise, the first card from the bottom is the previous to last.
	assert_eq(pile.get_child(pile.get_child_count() - 2),pile.get_top_card(),
			'get_bottom_card returns() bottom card')
	assert_eq(pile.get_bottom_card(),pile.get_all_cards()[0],
			"get_all_cards() works without anything in viewpile")

func test_facedown_cards():
	var pile : Pile = cfc.NMAP.deck
	# We need a longer yield because we're also waiting for the richtextlabels
	# To populate, during which time, cards are left face-up
	yield(yield_for(0.3), YIELD)
	assert_eq(pile.get_top_card().is_faceup, pile.faceup_cards,\
			"Card has to be facedown when moved into pile")

func test_faceup_cards():
	var pile : Pile = cfc.NMAP.deck
	pile.faceup_cards = true
	yield(yield_for(0.1), YIELD)
	assert_eq(pile.get_top_card().is_faceup, pile.faceup_cards,\
			"Card has to be faceup when moved into pile")

func test_popup_view():
	var pile : Pile = cfc.NMAP.deck
	yield(yield_for(0.1), YIELD)
	var card_order := pile.get_all_cards()
	var ordered_cards := pile.get_all_cards()
	ordered_cards.sort_custom(CFUtils,"sort_scriptables_by_name")
	ordered_cards.invert()
	var ordered_card_names := []
	for o in ordered_cards:
		ordered_card_names.append(o.canonical_name)
	pile.populate_popup()
	yield(yield_for(0.7), YIELD)
	assert_eq(pile.get_all_cards(), card_order,\
			"Retrieved card order remains when viewed in pile")
	assert_eq(pile.get_all_cards(), retieve_popup_order(pile),\
			"Viewed card order from topleft, to botright")
	pile.pile_popup.hide()
	yield(yield_for(0.7), YIELD)
	pile.populate_popup(true)
	yield(yield_for(0.7), YIELD)
	assert_ne(retieve_popup_order(pile), card_order,\
			"Card order changed when viewed in order")
	var popup_card_names := []
	for c in retieve_popup_order(pile):
		popup_card_names.append(c.canonical_name)
	assert_eq(popup_card_names, ordered_card_names,\
			"Cards are ordered in view popup")
	pile.pile_popup.hide()
	yield(yield_for(0.7), YIELD)
	assert_eq(pile.get_all_cards(), card_order,\
			"Pile order resumed after being viewed ordered")


func retieve_popup_order(pile: Pile) -> Array:
	var popup_cards := []
	for obj in pile._popup_grid.get_children():
		if obj.get_child_count():
			# We have to insert instead of append because in a popup
			# window, we display the menu inverted, as in godot node hierarchy
			# the "top card" is the last node and therefore would be placed
			# on the last position in the grid.
			# But the natural way to read a card list popup, is to expect the
			# top card to be on the top right
#			popup_cards.append(obj.get_child(0))
			popup_cards.insert(0, obj.get_child(0))
	return(popup_cards)

func test_set_pile_name():
	var pile : Pile = cfc.NMAP.discard
	pile.pile_name = "GUT Test"
	assert_eq(pile.pile_name, pile.pile_name_label.text,
			"Label is renamed whe pile_name changes")


func test_shuffle_signal():
	var pile : Pile = cfc.NMAP.deck
	watch_signals(pile)
	pile.shuffle_cards(false)
	assert_signal_emitted(pile,"shuffle_completed",
			"shuffle_completed emited")
