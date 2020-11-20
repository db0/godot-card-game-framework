# Card Gaming Framework global config and control singleton
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
# BEGIN Behaviour Constants #
# Change the below to change how all cards behave to match your game.
#-----------------------------------------------------------------------------

const CARD_SIZE_MULTIPLIER := 0.5
# The amount of distance neighboring cards are pushed during card focus
#
# It's based on the card width. Bigger percentage means larger push.
const NEIGHBOUR_PUSH := 0.75
# The scale of the card while on the play area
const PLAY_AREA_SCALE := Vector2(0.8,0.8)
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
# The below vars predefine the position in your node structure 
# to reach the nodes relevant to the cards.
#
# Adapt this according to your node structure. Do not prepent /root in front, 
# as this is assumed.
#
# Optimally this should be moved to its own reference class and set in the autoloader
const nodes_map := {
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
var card_scale_while_dragging := Vector2(0.4,0.4)
# If true, then the game will use the card focusing method 
# where it scales up the card itself.
#
# It will also mean you cannot focus on card on the table.
var focus_style = FocusStyle.BOTH
# Unit Testing flag
var UT := false
#-----------------------------------------------------------------------------
# END Behaviour Constants #
#-----------------------------------------------------------------------------
# A dictionary of all our container nodes for easy access
var NMAP: Dictionary
# All our pile nodes
var piles: Array
# All our hand nodes
var hands: Array
# The card actively being dragged
var card_drag_ongoing: Card = null


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
	# The below code allows us to quickly refer to nodes meant to host cards
	# (i.e. parents) using an human-readable name
	if get_tree().get_root().has_node('Main'):
		for node in nodes_map.keys():
			NMAP[node]  = get_node('/root/Main/ViewportContainer/Viewport/'
					+ nodes_map[node])
		NMAP['main'] = get_node('/root/Main')
		# When Unite Testing, we want to always have both scaling options possible
		if UT:
			focus_style = FocusStyle.BOTH
	else:
		for node in nodes_map.keys():
			NMAP[node]  = get_node('/root/' + nodes_map[node])
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
