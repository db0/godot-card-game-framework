# This file contains just card definitions. See also `CardConfig.gd`

extends Reference

const SET = "Demo Set 2"
const CARDS := {
	"Test Card 3": {
		"Type": "Green",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, this card will flip face-down " \
				+ "and rotate 180 degrees a target.",
		"Cost": 0,
	},
	"Multiple Choices Test Card": {
		"Type": "Blue",
		"Tags": ["Tag 1","Tag 2"],
		"Requirements": "",
		"Abilities": "While on board, either rotate 90, or flip face-down." \
				+ "\n\nAfter a card is flipped, either rotate 90, " \
				+ "or flip face-down.",
		"Cost": 0,
	},
}
