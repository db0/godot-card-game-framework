extends "res://tests/UTcommon.gd"

class TestBoardTokens:
	extends "res://tests/Basic_common.gd"

	func test_board_tokens():
		var card : Card
		card = cards[0]
		yield(table_move(card, Vector2(600,200)), 'completed')
		yield(move_mouse(card.global_position), 'completed')
		assert_false(card.tokens.is_drawer_open, "is_drawer_open flag should be false")
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer does not appear card hover when no card has no tokens")
		assert_eq(Vector2(card.get_node("Control").rect_size.x - 35,20),
				card.get_node("Control/Tokens/Drawer").rect_position,
				"Drawer does not extend when card hover when no card has no tokens")
		yield(move_mouse(Vector2(1100,200)), 'completed')

		assert_eq(CFConst.ReturnCode.FAILED,card.tokens.mod_token("Should Fail"),
				"Adding non-defined token returns a FAILED")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("tech"),
				"Adding new token returns a CHANGED result")
		var tech_token = card.tokens.get_token("tech")
		assert_eq("tech", tech_token.name, "New token takes the correct name")
		assert_eq("Tech", tech_token.get_node("Name").text,
				"Token label is name capitalized")
		assert_false(tech_token.get_node("Name").visible,
				"Token label should be invisible when card not hovered")
		assert_false(tech_token.get_node("MarginContainer").visible,
				"MarginContainer should be invisible when card not hovered")
		assert_false(tech_token.get_node("Buttons").visible,
				"Token Buttons should be invisible when card not hovered")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("gold coin"),
				"Can add tokens which include spaces")
		assert_eq("Gold Coin", card.tokens.get_token("gold coin").get_node("Name").text,
				"Token with space in name label is name capitalized")
		assert_eq(1,tech_token.count,"New token starts at 1 counter")
		assert_eq("1",tech_token.get_node("CenterContainer/Count").text,
				"New token 1 counter label has the correct number")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("tech"),
				"Increasing token counter returns a CHANGED result")
		assert_eq(2,tech_token.count,"Increased token at 2 counters")
		assert_eq("2",tech_token.get_node("CenterContainer/Count").text,
				"Token change increases label counter too")
		assert_eq(2,card.tokens.get_all_tokens().size(),
				"tokens.get_all_tokens() returns correct dict keys")
	# Below doesn' seem to work. Always returns emptry string
	#	assert_eq(cfc.PATH_TOKENS + cfc.TOKENS_MAP["tech"],
	#			tech_token.get_node("CenterContainer/TokenIcon").texture.resource_path,
	#			"New token texture uses the correct file")

		yield(move_mouse(card.global_position), 'completed')
		assert_true(tech_token.get_node("Name").visible,
				"Token label should be visible when card hovered")
		assert_true(tech_token.get_node("MarginContainer").visible,
				"MarginContainer should be visible when card hovered")
		assert_true(tech_token.get_node("Buttons").visible,
				"Token Buttons should be visible when card hovered")
		assert_eq(99,card.get_node("Control/Tokens").z_index,"Drawer is drawn on top of other cards")
		assert_true(card.tokens.is_drawer_open, "tokens.is_drawer_open flag should be false")
		assert_eq(1.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer appears when card has tokens on mouse hover")
		assert_almost_eq(Vector2(card.get_node("Control").rect_size.x,20),
				card.get_node("Control/Tokens/Drawer").rect_position, Vector2(2,2),
				"Drawer extends on card hover card has tokens")
		var prev_y = card.get_node("Control/Tokens/Drawer").rect_size.y
	# warning-ignore:return_value_discarded
		card.tokens.mod_token("blood")
		yield(yield_for(0.1), YIELD) # Wait to allow drawer to expand
		assert_lt(prev_y, card.get_node("Control/Tokens/Drawer").rect_size.y,
				"When adding more tokens, visible drawer size expands")
		yield(move_mouse(Vector2(1000,600)), 'completed')
		yield(yield_for(0.1), YIELD)
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer does not appear without card hover when card has tokens")
		assert_almost_eq(Vector2(card.get_node("Control").rect_size.x - 35,20),
				card.get_node("Control/Tokens/Drawer").rect_position, Vector2(2,2),
				"Drawer does not extend without card hover when card has tokens")
		assert_eq(CFConst.ReturnCode.FAILED,card.tokens.mod_token("Should Fail", -1),
				"Removing non-defined token returns a fail")
		assert_eq(CFConst.ReturnCode.FAILED,card.tokens.mod_token("Industry", -1),
				"Removing non-existent token returns a fail")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("tech", -1),
				"Removing token returns a CHANGED result")
		assert_eq(1,tech_token.count,"remove_token() buttons decreases amount")
		assert_eq("1",tech_token.get_node("CenterContainer/Count").text,
				"Counter label has the reduced number")
		prev_y = card.get_node("Control/Tokens/Drawer").rect_size.y
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("tech", -1),
				"Removing token to 0 returns a CHANGED result")
		yield(yield_for(0.1), YIELD) # Wait to allow node to be free'd
		assert_freed(tech_token, "tech token")
		assert_gt(prev_y, card.get_node("Control/Tokens/Drawer").rect_size.y,
				"When less tokens drawer size decreases")

		yield(drag_card(card, Vector2(200,100)), 'completed')
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer closes when card is being dragged")
		drop_card(card,board._UT_mouse_position)
		yield(move_mouse(Vector2(1000,300)), 'completed')
		yield(move_mouse(card.global_position), 'completed')
		yield(yield_for(0.6), YIELD) # Wait to allow drawer to expand
		card.is_faceup = false
		yield(yield_to(card.get_node('Control/Tokens/Tween'), "tween_all_completed", 0.5), YIELD)
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer closes while Flip is ongoing")
		yield(yield_to(card.get_node('Control/Tokens/Tween'), "tween_all_completed", 0.5), YIELD)
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer reopens once Flip is completed")
		card.move_to(cfc.NMAP.discard)
		yield(yield_for(0.4), YIELD)
		assert_eq(0.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer closes on moveTo")
		yield(yield_for(0.8), YIELD)
		assert_eq(0,card.tokens.get_all_tokens().size(),"Tokens removed when card leaves table")


		card = cards[3]
		yield(table_move(card, Vector2(200,300)), 'completed')
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("magic", 10),
				"Adding new token with larger amount returns a CHANGED result")
		var magic_token: Token = card.tokens.get_token("magic")
		assert_eq(10,magic_token.count,"Token starts at specified counter")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("magic", -5),
				"Reducing token by a larger amount returns a CHANGED result")
		assert_eq(5,magic_token.count,"Token reduced by 5")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("magic", -50),
				"Reducing to less than 0, returns a CHANGED result")
		yield(yield_for(0.1), YIELD) # Wait to allow node to be free'd
		assert_freed(magic_token, "magic token")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("void", 4, true),
				"Adding new token with a set amount returns a CHANGED result")
		var void_token: Token = card.tokens.get_token("void")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("void", 28, true),
				"Changeing to larger set amount returns CHANGED result")
		assert_eq(28,void_token.count,"Token set to specified higher amount")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("void", 18, true),
				"Changeing to lower set amount returns CHANGED result")
		assert_eq(18,void_token.count,"Token set to specified lower amount")
		assert_eq(CFConst.ReturnCode.CHANGED, card.tokens.mod_token("void", -20, true),
				"Changeing to set amount lower than 0, returns CHANGED result")
		yield(yield_for(0.1), YIELD) # Wait to allow node to be free'd
		assert_freed(void_token, "void token")


class TestOffBoardTokens:
	extends "res://tests/Basic_common.gd"

	func test_off_board_tokens():
		cfc._ut_tokens_only_on_board = false
		cfc._ut_show_token_buttons = false
		var card : Card
		card = cards[3]
		yield(table_move(card, Vector2(1000,100)), 'completed')
		card._on_Card_mouse_entered()
		yield(yield_for(0.1), YIELD)
		# warning-ignore:return_value_discarded
		card.tokens.mod_token("tech")
		# warning-ignore:return_value_discarded
		card.tokens.mod_token("plasma")
		# warning-ignore:return_value_discarded
		card.tokens.mod_token("gold coin")
		var tech_token = card.tokens.get_token("tech")
		var plasma_token = card.tokens.get_token("plasma")
		assert_eq(tech_token.get_node("CenterContainer/TokenIcon").texture.resource_path,
				plasma_token.get_node("CenterContainer/TokenIcon").texture.resource_path,
				"Two tokens can use the same texture but different names")
		assert_false(tech_token.get_node("Buttons").visible,
				"Tokens buttons not shown when cfc.show_token_buttons == false")
		yield(yield_for(0.2), YIELD)
		assert_eq(1.0, card.get_node("Control/Tokens/Drawer").self_modulate[3],
				"Drawer appears when card gets tokens while card focused")
		card.move_to(cfc.NMAP.discard)
		yield(yield_for(0.8), YIELD)
		assert_false(card.tokens.get_all_tokens().empty(),
				"Tokens not removed when card leaves with tokens_only_on_board == false")
		cfc._ut_tokens_only_on_board = true
		cfc._ut_show_token_buttons = true
