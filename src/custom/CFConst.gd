# Card Gaming Framework global Behaviour Constants
#
# This class contains constants which handle how all the framework behaves.
#
# Tweak the values to match your game requirements.
class_name CFConst
extends Reference

# The possible return codes a function can return
#
# * OK is returned when the function did not end up doing any changes
# * CHANGE is returned when the function modified the card properties in some way
# * FAILED is returned when the function failed to modify the card for some reason
enum ReturnCode {
	OK,
	CHANGED,
	FAILED,
}
# Options for pile shuffle styles.
# * auto: Will choose a shuffle animation depending on the amount of
#	cards in the pile.
# * none: No shuffle animation for this pile.
# * random: Will choose a random shuffle style each time a shuffle is requested.
# * corgi: Looks better on a small amount of cards (0 to 30)
# * splash: Looks better on a moderate amount of cards (30+)
# * snap: For serious people with no time to waste.
# * overhand: Shuffles deck in 3 vertical raises. Best fit for massive amounts (60+)
enum ShuffleStyle {
	AUTO,
	NONE,
	RANDOM,
	CORGI,
	SPLASH,
	SNAP,
	OVERHAND,
}
# The card size you want your  cards to have.
# This will also adjust all CardContainers to match
# If you modify this property, you **must** adjust
# the min_rect of the various control nodes inside the card front and back scenes.
const CARD_SIZE := Vector2(150,240)
# Switch this off to disable fancy movement of cards during draw/discard
const FANCY_MOVEMENT := true
# The focus style selected for this game. See enum `FocusStyle`
const FOCUS_STYLE = CFInt.FocusStyle.BOTH
# Controls how the card will be magnified in the focus viewport.
# Set to either "resize" or "scale"
#
# If set to scale, will magnify the card during viewport focus
# using godot scaling. It doesn't require any extra configuration when your
# Card font layout is changed, but it doesn't look quite as nice.
#
# If set to resize, will resize the card's viewport dupe's dimentions.
# This prevent blurry text, but needs more setup in the
# card's front and card back scripts.
const VIEWPORT_FOCUS_ZOOM_TYPE = "resize"
# If set to true, the hand will be presented in the form of an oval shape
# If set to false, the hand will be presented with all cards
# horizontally aligned
#
# If you allow the player to modify this with cfc.set_settings()
# Then that will always take priority
const HAND_USE_OVAL_SHAPE := true
# The below scales down cards down while being dragged.
#
# if you don't want this behaviour, change it to Vector2(1,1)
const CARD_SCALE_WHILE_DRAGGING := Vector2(0.4, 0.4)
# The location and name of the file into which to store game settings
const SETTINGS_FILENAME := "user://CGFSettings.json"
# The location where this game will store deck files
const DECKS_PATH := "user://Decks/"
# The path where the Card Game Framework core files exist.
# (i.e. mandatory scenes and scripts)
const PATH_CORE := "res://src/core/"
# The path where scenes and scripts customized for this specific game exist
# (e.g. board, card back etc)
const PATH_CUSTOM := "res://src/custom/"
# The path where card template scenes exist.
# These is usually one scene per type of card in the game
const PATH_CARDS := PATH_CUSTOM + "cards/"
# The path where the set definitions exist.
# This includes Card definition and card script definitions.
const PATH_SETS := PATH_CARDS + "sets/"
# The path where assets needed by this game are placed
# such as token images
const PATH_ASSETS := "res://assets/"
# The text which is prepended to files to signify the contain
# Card definitions for a specific set
const CARD_SET_NAME_PREPEND := "SetDefinition_"
# The text which is prepended to files to signify the contain
# script definitions for a specific set
const SCRIPT_SET_NAME_PREPEND := "SetScripts_"
# This specifies the location of your token images.
# Tokens are always going to be seeked at this location
const PATH_TOKENS := PATH_ASSETS + "tokens/"
# If you wish to extend the OVUtils, extend the class with your own
# script, then point to it with this const.
const PATH_OVERRIDABLE_UTILS := PATH_CORE + "OverridableUtils.gd"
# This specifies the path to the Scripting Engine. If you wish to extend
# The scripting engine functionality with your own tasks,
# Point this to your own script file.
const PATH_SCRIPTING_ENGINE := PATH_CORE + "ScriptingEngine.gd"
# This specifies the path to the [ScriptPer] class file.
# We don't reference is by class name to avoid cyclic dependencies
# And this also allows other developers to extend its functionality
const PATH_SCRIPT_PER := PATH_CORE + "ScriptPer.gd"
# This specifies the path to the Alterant Engine. If you wish to extend
# The alterant engine functionality with your own tasks,
# Point this to your own script file.
const PATH_ALTERANT_ENGINE := PATH_CORE + "AlterantEngine.gd"
# This specifies the path to the MousePointer. If you wish to extend
# The mouse pointer functionality with your own code,
# Point this to your own scene file with a scrip extending Mouse Pointer.
const PATH_MOUSE_POINTER := PATH_CORE + "MousePointer.tscn"
# The amount of distance neighboring cards are pushed during card focus
#
# It's based on the card width. Bigger percentage means larger push.
const NEIGHBOUR_PUSH := 0.75
# The scale of a card while on the play area
const PLAY_AREA_SCALE := Vector2(1, 1) * 0.8
# The margin towards the bottom of the viewport on which to draw the cards.
#
# More than 0 and the card will appear hidden under the display area.
#
# Less than 0 and it will float higher than the bottom of the viewport
const BOTTOM_MARGIN_MULTIPLIER := 0.5
# Here you can adjust the amount of offset towards a side of their host card
# that attachments are placed.
#
# This is a multiplier based on the card size.
#
# You define which placement offset an attachment uses by setting the
# "attachment_offset" exported variable on the card scene
const ATTACHMENT_OFFSET := [
	# TOP_LEFT
	Vector2(-0.2,-0.2),
	# TOP
	Vector2(0,-0.2),
	# TOP_RIGHT
	Vector2(0.2,-0.2),
	# RIGHT
	Vector2(0.2,0),
	# LEFT
	Vector2(-0.2,0),
	# BOTTOM_LEFT
	Vector2(-0.2,0.2),
	# BOTTOM
	Vector2(0,0.2),
	# BOTTOM_RIGHT
	Vector2(0.2,0.2),
]
# The colour to use when hovering over a card.
#
# Reduce the multiplier to reduce glow effect or stop it altogether
const FOCUS_HOVER_COLOUR := Color(1, 1, 1) * 1
# The colour to use when hovering over a card with an attachment to signify
# a valid host.
#
# We multiply it a bit to make it as bright as FOCUS_HOVER_COLOUR
# for the glow effect.
#
# Reduce the multiplier to reduce glow effect or stop it altogether
const HOST_HOVER_COLOUR := Color(1, 0.8, 0) * 1
# The colour to use when hovering over a card with an targetting arrow
# to signify a valid target.
#
# We multiply it a bit to make it about as bright
# as FOCUS_HOVER_COLOUR for the glow effect.
#
# Reduce the multiplier to reduce glow effect or stop it altogether.
const TARGET_HOVER_COLOUR := Color(0, 0.4, 1) * 1.3
# The colour to use when hovering over a card with an targetting arrow
# to signify a valid target
#
# We are using the same colour as the TARGET_HOVER_COLOUR since they
# they match purpose
#
# You can change the colour to something else if  you want however
const TARGETTING_ARROW_COLOUR := TARGET_HOVER_COLOUR
# The below const defines what string to put between these elements.
# Returns a color code to be used to mark the state of cost to pay for a card
# * IMPOSSIBLE: The cost of the card cannot be paid.
# * INCREASED: The cost of the card can be paid but is increased for some reason.
# * DECREASED: The cost of the card can be paid and is decreased for some reason.
# * OK: The cost of the card can be paid exactly.
const CostsState := {
	"IMPOSSIBLE": Color(1, 0, 0) * 1.3,
	"INCREASED": Color(1, 0.5, 0) * 1.3,
	"DECREASED": Color(0.5, 1, 0) * 1.3,
	"OK": FOCUS_HOVER_COLOUR,
}
# This is used when filling in card property labels in [Card].setup()
# when the property is an array, the label will still display it as a string
# but will have to join its elements somehow.
const ARRAY_PROPERTY_JOIN := ' - '
# If this is set to false, tokens on cards
# will not be removed when they exit the board
const TOKENS_ONLY_ON_BOARD := true
# If true, each token will have a convenient +/- button when expanded
# to allow the player to add a remove more of the same
const SHOW_TOKEN_BUTTONS := false
# This dictionary contains your defined tokens for cards
#
# The key is the name of the token as it will appear in your scene and labels
# **Please use lowercase only for the key**
#
# The value is the filename which contains your token image. The full path will
# be constructed using the PATH_TOKENS variable
#
# This allows us to reuse a token image for more than 1 token type
const TOKENS_MAP := {
	'tech': 'blue.svg',
	'plasma': 'blue.svg',
	'bio': 'green.svg',
	'industry': 'grey.svg',
	'magic': 'purple.svg',
	'blood': 'red.svg',
	'gold coin': 'yellow.svg',
	'void': 'black.svg',
}
const STATS_URI := "http://127.0.0.1"
const STATS_PORT := 8000
# The location of your NakamaClient script. This setup allows the CGF to work
# even if you remove the networking folder completely (e.g. for a single-player game)
# To make this work, make sure you have the Nakama singleton loaded as 'nakama'
# as [per instructions](https://github.com/heroiclabs/nakama-godot)

const NETWORKING_PATH = "res://src/networking/"
const NAKAMA_CLIENT_LOCATION = NETWORKING_PATH + "NakamaClient.gd"
const NAKAMA_MATCHMAKING_PATH = NETWORKING_PATH + "matchmaking/"
