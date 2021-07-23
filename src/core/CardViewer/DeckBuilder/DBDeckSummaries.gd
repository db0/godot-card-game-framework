# Shows details about the current deck as a whole
class_name DBDeckSummaries
extends HBoxContainer

# Stores the location of the deck-minimun label
var deck_min_label : Label

# We use this function instead of _ready()
# In order to make it overridable by customized scenes
func setup() -> void:
	deck_min_label = $CardCount
