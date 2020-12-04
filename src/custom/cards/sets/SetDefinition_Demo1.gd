# This file contains just card definitions. See also `CardConfig.gd`

extends Reference

const SET = "Demo Set 1"
const CARDS := {
	"Test Card 1": {
		"Type": "Blue",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this will rotate itself 90 degrees." \
				+ "\n\nWhile in hand, this card will go back in the deck.",
		"Cost": 0,
	},
	"Test Card 2": {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this card will discard itself " \
				+ "and another target.",
		"Cost": 0,
	},
}
