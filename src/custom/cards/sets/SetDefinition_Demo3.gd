# This file contains just card definitions. See also `CardConfig.gd`

extends Reference

const SET = "Demo Set 3"
const CARDS := {
	"Test Card 5": {
		"Type": "Custom",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this card will discard itself " \
				+ "and another target."\
				+ "\n\nWhile on the hand, this card will remove itself " \
				+ "from the game",
		"Cost": 2,
		"Power": 5,
		"BottomType":1,
		"MiddleType":1,
		"TopType":1,
	},
}
