# This file contains just card definitions. See also `CardConfig.gd`

extends Reference

const SET = "Demo Set 2"
const CARDS := {
	"Test Card 3": {
		"Type": "Green",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this card will flip face-down " \
				+ "and rotate 180 degrees a target." \
				+ "\n\nWhile on the hand, this card will remove " \
				+ "a target card from the game",
		"Cost": 0,
	},
}
