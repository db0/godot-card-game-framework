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
# The focus style used by the engine
# * SCALED means that the cards simply scale up when moused over in the hand
# * VIEWPORT means that a larger version of the card appears when mousing over it
# * BOTH means SCALED + VIEWPORT
enum FocusStyle {
	SCALED
	VIEWPORT
	BOTH
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
# Options for displacing choosing which of the [CardContainer]s
# sharing the same anchor to displace more.
# * LOWER: The CardContainer with the lowest index will be displaced more
# * HIGHER: The CardContainer with the highest index will be displaced more
# Do not mix containers using both of these settings, unless the conflicting
# container's OverlapShiftDirection is set to "NONE"
enum IndexShiftPriority{
	LOWER
	HIGHER
}
# Options for displacing [CardContainer]s sharing the same anchor
# * NONE: This CardContainer will never be displaced from its position
# * UP: This CardContainer will be displaced upwards. Typically used when
#	this container is using one of the bottom anchors.
# * DOWN: This CardContainer will be displaced downwards.Typically used when
#	this container is using one of the top anchors.
# * LEFT: This CardContainer will be displaced leftwards. Typically used when
#	this container is using one of the right anchors.
# * RIGHT: This CardContainer will be displaced rightwards.Typically used when
#	this container is using one of the left anchors.
enum OverlapShiftDirection{
	NONE
	UP
	DOWN
	LEFT
	RIGHT
}

# The card size you want your  cards to have.
# This will also adjust all CardContainers to match
# If you modify this property, you **must** adjust
# the min_rect of the various control nodes inside the card front and back scenes.
const CARD_SIZE := Vector2(150,240)
# When this is set, the player cannot drop cards on the board.
# If the card is not hovering over a pile when it is dropped, it will
# simply return to its originating container
const DISABLE_BOARD_DROP := false
# Switch this off to disable fancy movement of cards during draw/discard
const FANCY_MOVEMENT := true
# The focus style selected for this game. See enum `FocusStyle`
const FOCUS_STYLE = FocusStyle.BOTH
# If set to true, the hand will be presented in the form of an oval shape
# If set to false, the hand will be presented with all cards
# horizontally aligned
const HAND_USE_OVAL_SHAPE := true
# The below scales down cards down while being dragged.
#
# if you don't want this behaviour, change it to Vector2(1,1)
const CARD_SCALE_WHILE_DRAGGING := Vector2(0.4, 0.4)
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
const SCRRIPT_SET_NAME_PREPEND := "SetScripts_"
# This specifies the location of your token images.
# Tokens are always going to be seeked at this location
const PATH_TOKENS := PATH_ASSETS + "tokens/"
# This specifie the path the the Scripting Engine. If you wish to extend
# The scripting engine functionality with your own tasks,
# Point this to your own script file.
const PATH_SCRIPTING_ENGINE := PATH_CORE + "ScriptingEngine.gd"
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
# The amount of offset towards the bottom of their host card
# that attachments are placed.
#
# This is a multiplier of the card size.
#
# Put a negative number here if you want attachments to offset
# towards the top of the host.
const ATTACHMENT_OFFSET := -0.2
# The colour to use when hovering over a card.
#
# Reduce the multiplier to reduce glow effect or stop it altogether
const FOCUS_HOVER_COLOUR := Color(1, 1, 1) * 1
# The colour to use when hovering over a card in hand and the
# `_check_play_costs()` function returns false, signifying the card
# should be be draggable out of the hand
#
# Reduce the multiplier to reduce glow effect or stop it altogether
const CANNOT_PAY_COST_COLOUR := Color(1, 0, 0) * 1.3
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
# This is used when filling in card property labels in [Card].setup()
# when the property is an array, the label will still display it as a string
# but will have to join its elements somehow.
#
# The below const defines what string to put between these elements.
const ARRAY_PROPERTY_JOIN := ' - '
# If this is set to false, tokens on cards
# will not be removed when they exit the board
const TOKENS_ONLY_ON_BOARD := true
# If true, each token will have a convenient +/- button when expanded
# to allow the player to add a remove more of the same
const SHOW_TOKEN_BUTTONS := false
# If true, the player will not be able to drop dragged cards back into
# CardContainers. The player will only be allowed to drop cards to the board
# or back into the container they picked them front
# The game logic will have to provide another way to send cards to the various
# piles
# Be careful with this setting, as it will allow the player to drop cards
# on top of the hand or pile areas.
const DISABLE_DROPPING_TO_CARDCONTAINERS := false
# If true, the player will not be able to drag cards out of the hand manually
const DISABLE_DRAGGING_FROM_HAND := false
# If true, the player will not be able to drag cards around the board manually
const DISABLE_DRAGGING_FROM_BOARD := false
# If true, the player will not be able to drag cards out of piles
# (Either directly from top, or from popup windows)
const DISABLE_DRAGGING_FROM_PILE := false
# This dictionary contains your defined tokens for cards
#
# The key is the name of the token as it will appear in your scene and labels
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
