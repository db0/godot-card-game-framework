# Card Gaming Framework Control Singleton
#
# Add it to your autoloads with the name 'cfc'
class_name CFControl
extends Node

signal all_nodes_mapped()
#-----------------------------------------------------------------------------
# BEGIN Control Variables
# These variables change the way the cards behave.
# They initiate with the value from CFConst, but they can be modified
# during runtime as well
#-----------------------------------------------------------------------------

# Switch this off to disable fancy movement of cards during draw/discard
var fancy_movement := CFConst.FANCY_MOVEMENT
# If true, then the game will use the card focusing method
# where it scales up the card itself.
#
# It will also mean you cannot focus on card on the table.
var focus_style := CFConst.FOCUS_STYLE
# If set to true, the hand will be presented in the form of an oval shape
# If set to false, the hand will be presented with all cards
# horizontally aligned
var hand_use_oval_shape := CFConst.HAND_USE_OVAL_SHAPE

#-----------------------------------------------------------------------------
# END Control Variables
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# BEGIN Unit Testing Variables
#-----------------------------------------------------------------------------

# Unit Testing flag
var ut := false
var _ut_tokens_only_on_board := CFConst.TOKENS_ONLY_ON_BOARD
var _ut_show_token_buttons := CFConst.SHOW_TOKEN_BUTTONS

#-----------------------------------------------------------------------------
# END Unit Testing Variables
#-----------------------------------------------------------------------------

# If this is false, all CardContainers will pause in their ready() scene
# until all other CardContainers have been mapped.
var are_all_nodes_mapped := false
# The games initial Random Number Generator seed.
# When this stays the same, the game randomness will always play the predictable.
var game_rng_seed := "CFC Random Seed" setget set_seed
# This will store all card properties which are placed in the card labels
var card_definitions := {}
# This will store all card scripts
var set_scripts := {}
# A class to propagate script triggers to all cards.
var signal_propagator = SignalPropagator.new()
# A dictionary of all our container nodes for easy access
var NMAP: Dictionary
# The card actively being dragged
var card_drag_ongoing: Card = null
# Switch used for seeing debug info
var _debug := false
# Game random number generator
var game_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# We reset our node mapping variables every time
	# as they repopulate during unit testing many times.
	# warning-ignore:return_value_discarded
	connect("all_nodes_mapped", self, "_on_all_nodes_mapped")
	# We need to reset these values for UNIT testing
	NMAP = {}
	are_all_nodes_mapped = false
	card_drag_ongoing = null
	# The below takes care that we adjust some settings when testing via Gut
	if get_tree().get_root().has_node('Gut'):
		ut = true
		_debug = true
	# Initialize the game random seed
	set_seed(game_rng_seed)
	card_definitions = load_card_definitions()


func _on_all_nodes_mapped() -> void:
	if get_tree().get_root().has_node('Main'):
		# When Unit Testing, we want to always have both scaling options possible
		if ut:
			focus_style = CFConst.FocusStyle.BOTH
	else:
		# If we're not using the main viewport scene, we need to fallback
		# to the basic focus
		focus_style = CFConst.FocusStyle.SCALED
		# To prevent accidental switching this option when there's no other
		# viewports active
		if NMAP.board: # Needed for UT
			NMAP.board.get_node("ScalingFocusOptions").disabled = true
	set_scripts = load_script_definitions()


# The below code allows us to quickly refer to nodes meant to host cards
# (i.e. parents) using an human-readable name.
#
# Since the fully mapped NMAP variable is critical for the good functioning
# of the framework, all CardContainers will wait in their ready() process
# for NMAP to be completed.
func map_node(node) -> void:
	# The nmap always stores lowercase keys. Each key is a node name
	NMAP[node.name.to_lower()] = node
	var add_main = 0
	# Since we allow the game to run directly from the board scene,
	# we need to check if a viewport called Main is being used.
	if get_tree().get_root().has_node('Main'):
		add_main = 1
	# The below variable counts how many nodes we're expecting to map inside
	# NMAP. We calculate this by using node groups. For this, the piles
	# and hands have to be added to group from the editor (i.e. not only
	# via code in the ready() method).
	# The amount we're looking for is the sum of all CardContainers
	# +1 for the board, +1 if we're using a focus viewport
	var all_nodes : int = get_tree().get_nodes_in_group("hands").size() \
			+ get_tree().get_nodes_in_group("piles").size() + 1  + add_main
	# If the amount of node maps we have is equal to all nodes in gr
	if NMAP.size() == all_nodes:
		are_all_nodes_mapped = true
		# Once all nodes have been mapped, we emit a signal so that
		# all nodes waiting to complete their ready()  method, can continue.
		emit_signal("all_nodes_mapped")


# Setter for the ranom seed.
func set_seed(_seed: String) -> void:
	game_rng_seed = _seed
	game_rng.set_seed(hash(game_rng_seed))


# Instances and returns a Card object, based on its name.
func instance_card(card_name: String) -> Card:
	# We discover the template from the "Type"  property defined
	# in each card. Any property can be used
	var template = load(CFConst.PATH_CARDS
			+ card_definitions[card_name][CardConfig.SCENE_PROPERTY] + ".tscn")
	var card = template.instance()
	# We set the card_name variable so that it's able to be used later
	card.card_name = card_name
	if card_definitions[card_name][CardConfig.SCENE_PROPERTY] == "Custom":
		card.bottom_type = card_definitions[card_name]["BottomType"]
		card.middle_type = card_definitions[card_name]["MiddleType"]
		card.top_type = card_definitions[card_name]["TopType"]
	return(card)


# Returns a Dictionary with the combined Card definitions of all set files
func load_card_definitions() -> Dictionary:
	var set_definitions := CFUtils.list_files_in_directory(
				CFConst.PATH_SETS, CFConst.CARD_SET_NAME_PREPEND)
	var combined_sets := {}
	for set_file in set_definitions:
		var set_dict = load(CFConst.PATH_SETS + set_file).CARDS
		for dict_entry in set_dict:
			combined_sets[dict_entry] = set_dict[dict_entry]
	return(combined_sets)


# Returns a Dictionary with the combined Script definitions of all set files
func load_script_definitions() -> Dictionary:
	var script_definitions := CFUtils.list_files_in_directory(
				CFConst.PATH_SETS, CFConst.SCRRIPT_SET_NAME_PREPEND)
	var combined_scripts := {}
	for card_name in card_definitions.keys():
		for script_file in script_definitions:
			if combined_scripts.get(card_name):
				break
			var scripts_obj = load(CFConst.PATH_SETS + script_file).new()
			# scripts are not defined as constants, as we want to be
			# able to refer specific variables inside them
			# such as cfc.deck etc. Instead they contain a
			# method which returns the script for the requested card name
			var card_script = scripts_obj.get_scripts(card_name)
			if not card_script.empty():
				combined_scripts[card_name] = card_script
	return(combined_scripts)


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
		"card_properties_modified",
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
