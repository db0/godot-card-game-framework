### Card Gaming Framework Global Config
extends Node

#-----------------------------------------------------------------------------
# BEGIN Behaviour Constants #
# Change the below to change how all cards behave to match your game.
#-----------------------------------------------------------------------------


const card_size_multiplier := 0.5
# The amount of distance neighboring cards are pushed during card focus
# It's based on the card width. Bigger percentage means larger push.
const neighbour_push := 0.75

# The scale of the card while on the play area
const play_area_scale := Vector2(0.8,0.8)

# The margin towards the bottom of the viewport on which to draw the cards.
# More than 0 and the card will appear hidden under the display area.
# Less than 0 and it will float higher than the bottom of the viewport
const bottom_margin_multiplier := 0.5

# Switch this off to disable fancy movement of cards during draw/discard
var fancy_movement := true

# The below scales down cards down while being dragged
# if you don't want this behaviour, change it to Vector2(1,1)
var card_scale_while_dragging := Vector2(0.4,0.4)

# If true, then the game will use the card focusing method where it scales up the card itself.
# It will also mean you cannot focus on card on the table.
var focus_style = FocusStyle.BOTH
enum FocusStyle { 
	SCALED					#0
	VIEWPORT				#1
	BOTH					#2
}
# The below vars predefine the position in your node structure to reach the nodes relevant to the cards
# Adapt this according to your node structure. Do not prepent /root in front, as this is assumed
const nodes_map := { # Optimally this should be moved to its own reference class and set in the autoloader
	'board': "Board",
	'hand': "Board/Hand",
	'deck': "Board/Deck",
	'discard': "Board/DiscardPile"
	}

const pile_names = ['deck','discard']
const hand_names = ['hand']
var UT := false # Unit Testing flag
#-----------------------------------------------------------------------------
# END Behaviour Constants #
#-----------------------------------------------------------------------------

var NMAP: Dictionary # A dictionary of all our container nodes for easy access
var piles: Array # All our piles
var hands: Array # All our hands

var card_drag_ongoing: Card = null # The card actively being dragged
var done = false
func _ready() -> void:
	# We reset their contents every time as they repopulated during unit testing many times.
	NMAP = {}
	piles = []
	hands = []
	card_drag_ongoing = null
	# The below takes care that we adjust some settings when testing via Gut
	if get_tree().get_root().has_node('Gut'):
		UT = true
	# The below code allows us to quickly refer to nodes meant to host cards (i.e. parents)
	# using an human-readable name
	if get_tree().get_root().has_node('Main'):
		for node in cfc_config.nodes_map.keys():
			NMAP[node]  = get_node('/root/Main/ViewportContainer/Viewport/' + nodes_map[node])
		NMAP['main'] = get_node('/root/Main')
		# When Unite Testing, we want to always have both scaling options possible
		if UT:
			focus_style = cfc_config.FocusStyle.BOTH
	else:
		for node in cfc_config.nodes_map.keys():
			NMAP[node]  = get_node('/root/' + nodes_map[node])
		# If we're not using the main viewport scene, we need to fallback to the basic focus
		focus_style = cfc_config.FocusStyle.SCALED
		# To prevent accidental switching this option when there's no other viewports active
		if NMAP.board: # Needed for UT
			NMAP.board.get_node("ScalingFocusOptions").disabled = true
		# The below loops, populate two arrays which allows us to quickly figure out if a container is a pile or hand
	for name in pile_names:
		piles.append(NMAP[name])
	for name in hand_names:
		hands.append(NMAP[name])
