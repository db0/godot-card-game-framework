# This class allows you to preload your set definitions and set scripts for your game
# To use the advantages of the compiler
class_name SetPreload
extends Node

# The preloaded card sets. Each entry in this list must be a preload() for a set definition gdscript
# This constant is optional. If this is left empty
# The game will load the sets by scanning the directories in runtime
const CARD_SETS := []
# The preloaded card scripts. Each entry in this list must be a preload() for a set scripts gdscript
# This constant is optional. If this is left empty
# The game will load the scripts by scanning the directories in runtime
const CARD_SCRIPTS := []
