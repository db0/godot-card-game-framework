# This file contains just card definitions. See also `CardConfig.gd`

extends Reference

const SET = "Demo Set 1"
const CARDS := {
	"Test Card 1": {
		"Type": "Blue",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "Demo Requirements",
		"Abilities": "While on board, this will rotate itself." \
				+ "\n\nWhile in hand, this will spawn a test card on the board.",
		"Cost": 0,
		"Power": 0,
		"_max_allowed": 1,
	},
	"Test Card 2": {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this card will discard itself " \
				+ "and another target."\
				+ "\n\nWhile on the hand, this card will remove itself " \
				+ "from the game",
		"Cost": 2,
		"Power": 5,
		"_max_allowed": 10,
	},
	"Spawn Card": {
		"Type": "Token",
		"Tags": [],
		"Requirements": "",
		"Abilities": " ",
		"Cost": 0,
		"Power": 1,
		"_hide_in_deckbuilder": true,
	},
}
