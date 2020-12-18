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
# Properties provided in a list which are converted into a string for the
# label text, using the array_join() method
const PROPERTIES_ARRAYS := ["Tags"]
# This property matches the name of the scene file (without the .tcsn file)
# which is used as a template For this card.
const SCENE_PROPERTY = "Type"
# If the card text is about to exceed the card's rect due to too much
# expansion of a label using TEXT_EXPANSION_MULTIPLIER, then the
# below specified label will be shrunk extra to compensate.
const SHRINK_LABEL = "Abilities"
# This dictionary defines how much more a text field is allowed
# to expand their rect in order to fit its text before shrinking it.
#
# The defaults of 1 means the text will shrink until it all fits within
# the originally defined rect of the label.
#
# This is useful for things like card names, where it's preferable to expand
# The title rect, instead of reducing the name's font size too much.
#
# You have to be careful with this field, as allowing too much expansion will
# lead to cards with a lot of text, having it overflow their boundaries
const TEXT_EXPANSION_MULTIPLIER := {
	"Name": 2,
	"Tags": 1.2,
	"Cost": 3,
	"Power": 3,
}
