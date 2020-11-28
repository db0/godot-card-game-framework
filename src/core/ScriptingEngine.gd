# This class contains all the functionality required to perform
# full rules enforcement on any card.
#
# The automation is based on Tasks. Each "task" performs a very specific
# manipulation of the board state, based on using existing functions
# in the object manipulated.
# Therefore each task function provides effectively a text-based API
#
# This class is loaded by each card invidually, and contains a link
# back to the card object itself
class_name ScriptingEngine
extends Reference

# Emitted when all scripts have finished running
signal scripts_completed

# Contains a list of all the scripts still left to run for this card
var _running_scripts: Array
# The card which owns this Scripting Engine.
var _card_owner: Card
# Set when a card script wants to use a common target for all effects
# To avoid multiple targetting arrows

var custom: CustomScripts

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Sets the owner of this Scripting Engine
func _init(owner) -> void:
	_card_owner = owner
	custom = CustomScripts.new()


# The main engine starts here. It populates an array with all the scripts
# to execute, then goes one by one and sends them to the appropriate
# functions
func run_next_script() -> void:
	if _running_scripts.empty():
		#print('Scripting: All done!') # Debug
		emit_signal("scripts_completed")
	else:
		var script := CardScript.new(_card_owner,_running_scripts.pop_front())
		#print("Scripting: " + str(script)) # Debug
		# In case the script involves targetting, we need to wait on further
		# execution until targetting has completed
		if not script.has_init_completed:
			yield(script,"completed_init")
		if script.function_name == "custom_script":
			custom.custom_script(script)
		elif script.function_name:
			call(script.function_name, script)
		else:
			 # If card has a script but it's null, it probably not coded yet. Just go on...
			print("[WARN] Found empty script. Ignoring...")
		run_next_script()


# Task for rotating cards
#
# Requires the following keys:
# * "degrees": int
func rotate_card(script: CardScript) -> void:
	var card = script.subject
	card.card_rotation = script.get("degrees")


# Task for flipping cards
#
# Requires the following keys:
# * "set_faceup": bool
func flip_card(script: CardScript) -> void:
	var card = script.subject
	card.is_faceup = script.get("set_faceup")


# Task for moving cards to other containers
#
# Requires the following keys:
# * "container": CardContainer
# * (Optional) "dest_index": int
#
# The index position the card can be placed in, are:
# * index ==  -1 means last card in the CardContainer
# * index == 0 means the the first card in the CardContainer
# * index > 0 means the specific index among other cards.
func move_card_to_container(script: CardScript) -> void:
	var dest_index: int = script.get("dest_index")
	var card = script.subject
	card.move_to(script.get("container"), dest_index)


# Task for moving card to the board
#
# Requires the following keys:
# * "container": CardContainer
func move_card_to_board(script: CardScript) -> void:
	var card = script.subject
	card.move_to(cfc.NMAP.board, -1, script.get("board_position"))


# Task for moving card from one container to another
#
# Requires the following keys:
# * "card_index": int
# * "src_container": CardContainer
# * "dest_container": CardContainer
# * (Optional) "dest_index": int
#
# The index position the card can be placed in, are:
# * index ==  -1 means last card in the CardContainer
# * index == 0 means the the first card in the CardContainer
# * index > 0 means the specific index among other cards.
func move_card_cont_to_cont(script: CardScript) -> void:
	var card_index: int = script.get("pile_index")
	var src_container: CardContainer = script.get("src_container")
	var card = src_container.get_card(card_index)
	var dest_container: CardContainer = script.get("dest_container")
	var dest_index: int = script.get("dest_index")
	card.move_to(dest_container,dest_index)


# Task for playing a card to the board from a container directly.
#
# Requires the following keys:
# * "card_index": int
# * "src_container": CardContainer
func move_card_cont_to_board(script: CardScript) -> void:
	var card_index: int = script.get("pile_index")
	var src_container: CardContainer = script.get("src_container")
	var card := src_container.get_card(card_index)
	var board_position = script.get("board_position")
	card.move_to(cfc.NMAP.board, -1, board_position)


# Task from modifying tokens on a card
#
# Requires the following keys:
# * "token_name": String
# * "modification": int
# * (Optional) "set_to_mod": bool
func mod_tokens(script: CardScript) -> void:
	var card := script.subject
	var token_name: String = script.get("token_name")
	var modification: int = script.get("modification")
	var set_to_mod: bool = script.get("set_to_mod")
	# warning-ignore:return_value_discarded
	card.mod_token(token_name,modification,set_to_mod)


# Task from creating a new card instance on the board
#
# Requires the following keys:
# * "card_scene": path to .tscn file
# * "board_position": Vector2
func spawn_card(script: CardScript) -> void:
	var card_scene: String = script.get("card_scene")
	var board_position: Vector2 = script.get("board_position")
	var card: Card = load(card_scene).instance()
	cfc.NMAP.board.add_child(card)
	card.position = board_position
	card.state = card.ON_PLAY_BOARD


# Task from shuffling a CardContainer
#
# Requires the following keys:
# * "container": CardContainer
func shuffle_container(script: CardScript) -> void:
	var container: CardContainer = script.get("container")
	container.shuffle_cards()


# Task from making the owner card an attachment to another card
func attach_to_card(script: CardScript) -> void:
	var card := script.subject
	script.owner.attach_to_host(card)


# Task for attaching another card to the owner
func host_card(script: CardScript) -> void:
	var card := script.subject
	card.attach_to_host(script.owner)
