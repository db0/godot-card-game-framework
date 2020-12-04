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
	cards = draw_test_cards(5)
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[2]


func test_filtered_multiple_choice():
	card.scripts = {"card_flipped": {
				"trigger": "another",
				"filter_properties_trigger": {"Type": "Red"},
				"board": {
					"Rotate This Card": [
						{
							"name": "rotate_card",
							"subject": "self",
							"degrees": 90,
						}
					],
					"Flip This Card Face-down": [
						{
							"name": "flip_card",
							"subject": "self",
							"set_faceup": false,
						}
					]
				},
			},
	}
	yield(table_move(card, Vector2(100,200)), "completed")
	target.is_faceup = false
	yield(yield_for(0.1), YIELD)
	var menu = board.get_node("CardChoices")
	assert_true(menu.visible)
	menu._on_CardChoices_id_pressed(3)
	assert_eq("Rotate This Card",menu.selected_key)
	yield(yield_for(0.1), YIELD)
	menu.hide()
	assert_eq(card.card_rotation, 90,
			"Card should be rotated 90 degrees")
	yield(yield_for(0.1), YIELD)
	cards[3].is_faceup = false
	yield(yield_for(0.1), YIELD)
	menu = board.get_node("CardChoices")
	assert_null(menu, "menu should not appear when filter does not match")
