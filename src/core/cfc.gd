# Card Gaming Framework global config and control singleton
#
# Add it to your autoloads with the name 'cfc'
class_name CardFrameworkConfiguration
extends Node

# The focus style used by the engine
# * SCALED means that the cards simply scale up when moused over in the hand
# * VIEWPORT means that a larger version of the card appears when mousing over it
# * BOTH means SCALED + VIEWPORT
enum FocusStyle {
	SCALED					#0
	VIEWPORT				#1
	BOTH					#2
}



#-----------------------------------------------------------------------------
# BEGIN Behaviour Constants
# Change the below to change how all cards behave to match your game.
#-----------------------------------------------------------------------------

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
# This dictionary contains your defined tokens for cards
#
# The key is the name of the token as it will appear in your scene and labels
#
# The value is the filename which contains your token image. The full path will
# be constructed using the token_assets_path variable
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
# This specifies the location of your token images.
# Tokens are always going to be seeked at this location
const TOKEN_ASSETS_PATH = "res://assets/tokens/"
# The below vars predefine the position in your node structure
# to reach the nodes relevant to the cards.
#
# Adapt this according to your node structure. Do not prepent /root in front,
# as this is assumed.
#
# Optimally this should be moved to its own reference class
# and set in the autoloader
const NODES_MAP := {
	'board': "Board",
	'hand': "Board/Hand",
	'deck': "Board/Deck",
	'discard': "Board/DiscardPile"
	}
const pile_names = ['deck','discard']
const hand_names = ['hand']

# Switch this off to disable fancy movement of cards during draw/discard
var fancy_movement := true
# The below scales down cards down while being dragged.
#
# if you don't want this behaviour, change it to Vector2(1,1)
var card_scale_while_dragging := Vector2(0.4, 0.4)
# If true, then the game will use the card focusing method
# where it scales up the card itself.
#
# It will also mean you cannot focus on card on the table.
var focus_style = FocusStyle.BOTH
# If this is set to false, tokens on cards
# will not be removed when they exit the board
var tokens_only_on_board := true
# If true, each token will have a convenient +/- button when expanded
# to allow the player to add a remove more of the same
var show_token_buttons = false
# The games initial Random Number Generator seed.
# When this stays the same, the game randomness will always play the predictable.
var game_rng_seed := "CFC Random Seed" setget set_seed
# If set to true, the hand will be presented in the form of an oval shape
# If set to false, the hand will be presented with all cards
# horizontally aligned
var hand_use_oval_shape := true
#-----------------------------------------------------------------------------
# END Behaviour Constants
#-----------------------------------------------------------------------------

# This will store all card properties which are placed in the card labels
var card_definitions := {}
# A class to propagate script triggers to all cards.
var signal_propagator = SignalPropagator.new()
# Unit Testing flag
var UT := false
# A dictionary of all our container nodes for easy access
var NMAP: Dictionary
# All our pile nodes
var piles: Array
# All our hand nodes
var hands: Array
# The card actively being dragged
var card_drag_ongoing: Card = null
var debug := false
# Game random number generator
var game_rng: RandomNumberGenerator = RandomNumberGenerator.new()



func _ready() -> void:
	# We reset our node mapping variables every time
	# as they repopulate during unit testing many times.
	NMAP = {}
	piles = []
	hands = []
	card_drag_ongoing = null
	# The below takes care that we adjust some settings when testing via Gut
	if get_tree().get_root().has_node('Gut'):
		UT = true
		debug = true
	# The below code allows us to quickly refer to nodes meant to host cards
	# (i.e. parents) using an human-readable name
	if get_tree().get_root().has_node('Main'):
		for node in NODES_MAP.keys():
			NMAP[node]  = get_node('/root/Main/ViewportContainer/Viewport/'
					+ NODES_MAP[node])
		NMAP['main'] = get_node('/root/Main')
		# When Unite Testing, we want to always have both scaling options possible
		if UT:
			focus_style = FocusStyle.BOTH
	else:
		for node in NODES_MAP.keys():
			NMAP[node]  = get_node('/root/' + NODES_MAP[node])
		# If we're not using the main viewport scene, we need to fallback
		# to the basic focus
		focus_style = FocusStyle.SCALED
		# To prevent accidental switching this option when there's no other
		# viewports active
		if NMAP.board: # Needed for UT
			NMAP.board.get_node("ScalingFocusOptions").disabled = true
		# The below loops, populate two arrays which allows us to quickly
		# figure out if a container is a pile or hand
	for name in pile_names:
		piles.append(NMAP[name])
	for name in hand_names:
		hands.append(NMAP[name])
	# Initialize the game random seed
	set_seed(game_rng_seed)
	card_definitions = CardFrameworkUtils.load_card_definitions()



# Setter for seed.
func set_seed(_seed: String) -> void:
	game_rng_seed = _seed
	game_rng.set_seed(hash(game_rng_seed))


# Instances and returns a Card object, based on its name.
func instance_card(card_name: String) -> Card:
	# We discover the template from the "Type"  property defined
	# in each card. Any property can be used
	var template = load("res://src/custom/cards/"
			+ card_definitions[card_name][CardConfig.SCENE_PROPERTY] + ".tscn")
	var card = template.instance()
	card.setup(card_name)
	return(card)

# The SignalPropagator is responsible for collecting all card signals
# and asking all cards to check if there's any automation they need to perform
class SignalPropagator:

	# The working signals cards might send depending on their status changes
	const known_card_signals := [
		"card_rotated",
		"card_flipped",
		"card_viewed",
		"card_moved_to_board",
		"card_moved_to_pile",
		"card_moved_to_hand",
		"card_token_modified",
		"card_attached",
		"card_unattached",
		"card_targeted",
		]


	# When a new card is instanced, it connects all its known signals
	# to the SignalPropagator
	func connect_new_card(card):
		for sgn in known_card_signals:
			card.connect(sgn, self, "_on_Card_signal_received")


	# When a known signal is received, it asks all existing cards to check
	# If this triggers an automation for them
	#
	# This method requires that each signal also passes its own name in the
	# trigger variable, is this is the key sought in the CardScriptDefinitions
	func _on_Card_signal_received(
			trigger_card: Card, trigger: String, details: Dictionary):
		# We use Godot groups to ask every card to check if they
			# have [ScriptingEngine] triggers for this signal
		cfc.get_tree().call_group("cards",
				"execute_scripts",trigger_card,trigger,details)
