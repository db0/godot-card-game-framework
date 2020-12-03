# This class defines how the properties of the [Card] definition are to be
# used during `setup()`
class_name CardConfig
extends Reference

# Properties which are placed as they are in appropriate labels
const PROPERTIES_STRINGS := ["Type", "Requirements", "Abilities"]
# Properties which are converted into string using a format defined in setup()
const PROPERTIES_NUMBERS := ["Cost"]
# Properties provided in a list which are converted into a string for the 
# label text, using the array_join() method
const PROPERTIES_ARRAYS := ["Tags"]
# Properties which are not visible on the card front, but are nevertheless
# needed for the game in some way. 
const META := ["_template"]
# This property matches the name of the scene file (without the .tcsn file) 
# which is used as a template For this card.
const SCENE_PROPERTY = "Type"
