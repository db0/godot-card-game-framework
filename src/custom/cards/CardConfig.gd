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
const NUMBER_WITH_LABEL := []
# Properties provided in a list which are converted into a string for the
# label text, using the array_join() method
const PROPERTIES_ARRAYS := ["Tags"]
	# This property matches the name of the scene file (without the .tcsn file)
# which is used as a template For this card.
const SCENE_PROPERTY = "Type"
# These are number carrying properties, which we want to hide their label
# when they're 0, to allow more space for other labels.
const NUMBERS_HIDDEN_ON_0 := []
# If any strings in this array are found in the value of a PROPERTIES_NUMBERS property
# Then during comparisons, they are treated as if they were 0
const VALUES_TREATED_AS_ZERO := ['X', 'null', null]
# The cards where their [SCENE_PROPERTY](#SCENE_PROPERTY) value is in this list
# will not be shown in the deckbuilder.
#
# This is useful to prevent a whole class of cards from being shown in the
# deckbuilder, without adding `_hide_in_deckbuilder` to each of them
const TYPES_TO_HIDE_IN_CARDVIEWER := ["Token"]
# If this property exists in a card and is set to true, the card will not be
# displayed in the cardviewer
const BOOL_PROPERTY_TO_HIDE_IN_CARDVIEWER := "_hide_in_deckbuilder"
# When these keys are detected in the the "Tag" or "_keyword" fields, they
# will add extra info panel with the specified information to the player.
# See `OVUtils.populate_info_panels()`
const EXPLANATIONS = {
	"Tag 1": "Tag 1: You can add extra explanations for tags",
	"Keyword 1": "Keyword 1: You can specify explanations for keywords that might appear in the text",
	"Clarification A": "You can even provide longer clarification on card abilities"
}
# Allows the Card object and Card Viewer to replace specific entries during display.
# For example, you can mark that a cost of 'U' is displayed as an empty string ('').
# or a value of 0 to be displayed as 'X'.
# This const is a series of nested constants. 
# Each top key is a property name. 
# Each second-level key is value to replace.
# The value is the replacement.
# Example
#```
#const REPLACEMENTS = {
#	"Cost": {
#		'U': '',
#		-1: 'X',
#	}
#}
#```
const REPLACEMENTS = {}
# Defined bbcode which will replace the specified string in RichTextLabels
# For example, a key of 'damage' in this dictionary, will replace all instances
# of `{damage}` in card text with the provided bbcode value.
const CARD_BBCODE := {
	"damage": "[img={icon_size}]res://assets/icons/broadsword.png[/img]",
}
