# This class defines how the properties of the [Card] definition are to be
# used during `setup()`
#
# All the properties defined on the card json will attempt to find a matching
# label node inside the cards _card_labels dictionary.
# If one was not found, an error will be printed.
#
# The exception is properties starting with _underscore. This are considered
# Meta properties and the game will not attempt to display them on the card
# front.
class_name CardConfig
extends Reference

# Properties which are placed as they are in appropriate labels
const PROPERTIES_STRINGS := ["Type", "Requirements", "Abilities"]
# Properties which are converted into string using a format defined in setup()
const PROPERTIES_NUMBERS := ["Cost","Power"]
# The name of these properties will be prepended before their value to their label.
const NUMBER_WITH_LABEL := ["Cost","Power"]
# Properties provided in a list which are converted into a string for the
# label text, using the array_join() method
const PROPERTIES_ARRAYS := ["Tags"]
# This property matches the name of the scene file (without the .tcsn file)
# which is used as a template For this card.
const SCENE_PROPERTY = "Type"
# These are number carrying properties, which we want to hide their label
# when they're 0, to allow more space for other labels.
const NUMBERS_HIDDEN_ON_0 := []
# The cards where their [SCENE_PROPERTY](#SCENE_PROPERTY) value is in this list
# will not be shown in the deckbuilder.
#
# This is useful to prevent a whole class of cards from being shown in the
# deckbuilder, without adding `_hide_in_deckbuilder` to each of them
const TYPES_TO_HIDE_IN_DECKBUILDER := ["Token"]
const EXPLANATIONS = {
	"Tag 1": "Tag 1: You can add extra explanations for tags",
	"Keyword 1": "Keyword 1: You can specify explanations for keywords that might appear in the text",
	"Clarification A": "You can even provide longer clarification on card abilities"
}
const CARD_BBCODE := {
	"damage": "[img={icon_size}]res://assets/icons/broadsword.png[/img]",
}
