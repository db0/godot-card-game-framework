# This class contains all the functionality required to perform
# full rules enforcement on any card.
#
# The automation is based on [ScriptTask]s. Each such "task" performs a very specific
# manipulation of the board state, based on using existing functions
# in the object manipulated.
# Therefore each task function provides effectively a text-based API
#
# This class is loaded by each card invidually, and contains a link
# back to the card object itself
class_name ScriptingEngine
extends Reference

const _ASK_INTEGER_SCENE_FILE = CFConst.PATH_CORE + "AskInteger.tscn"
const _ASK_INTEGER_SCENE = preload(_ASK_INTEGER_SCENE_FILE)

# Emitted when all tasks have been run succesfully
signal tasks_completed

# This flag will be true if we're attempting to find if the card
# has costs that need to be paid, before the effects take place.
var costs_dry_run := false
# This is set to true whenever we're doing a cost dry-run
# and any task marked "is_cost" will not be able to manipulate the
# game state as required, either because the board is already at the
# requested state, or because something prevents it.
var can_all_costs_be_paid := true
# This is checked by the yield in [Card] execute_scripts()
# to know when the cost dry-run has completed, so that it can
# check the state of `can_all_costs_be_paid`.
var all_tasks_completed := false
# Stores the inputed integer from the ask_integer task
var stored_integer: int
# These task will require input from the player, so the subsequent task execution
# needs to wait for their completion
#
# This variable can be extended when this class is extended with new tasks
var wait_for_tasks = ["ask_integer"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Sets the owner of this Scripting Engine
func _init(card_owner: Card,
		scripts_queue: Array,
		check_costs := false) -> void:
	costs_dry_run = check_costs
	run_next_script(card_owner,
			scripts_queue.duplicate())


# The main engine starts here.
# It receives array with all the scripts to execute,
# then turns each array element into a ScriptTask object and
# send it to the appropriate tasks.
func run_next_script(card_owner: Card,
		scripts_queue: Array,
		prev_subjects := []) -> void:
	var ta: TargetingArrow = card_owner.targeting_arrow
	if scripts_queue.empty():
		#print('Scripting: All done!') # Debug
		# If we're doing a try run, we don't clean the targeting
		# as we will re-use it in the targeting phase.
		# We do clear it though if all the costs cannot be paid.
		if not costs_dry_run or (costs_dry_run and not can_all_costs_be_paid):
			ta.target_card = null
		if not costs_dry_run:
			ta.target_dry_run_card = null
		all_tasks_completed = true
		emit_signal("tasks_completed")
	# checking costs on multiple targeted cards in the same script,
	# is not supported at the moment due to the exponential complexities
	elif costs_dry_run and ta.target_dry_run_card and \
				scripts_queue[0].get(SP.KEY_SUBJECT) == "target":
			scripts_queue.pop_front()
			run_next_script(card_owner,
					scripts_queue,prev_subjects)
	else:
		var script := ScriptTask.new(
				card_owner,
				scripts_queue.pop_front(),
				prev_subjects,
				costs_dry_run,
				stored_integer)
		# In case the task involves targetting, we need to wait on further
		# execution until targetting has completed
		if not script.has_init_completed:
			yield(script,"completed_init")
		#print("Scripting Subjects: " + str(script.subjects)) # Debug
		if costs_dry_run and ta.target_card:
			ta.target_dry_run_card = ta.target_card
			ta.target_card = null
		if script.script_name == "custom_script":
			# This class contains the customly defined scripts for each
			# card.
			var custom := CustomScripts.new(costs_dry_run)
			custom.custom_script(script)
		elif script.script_name:
			if script.is_valid \
					and (not costs_dry_run
						or (costs_dry_run and script.get_property(SP.KEY_IS_COST))):
				#print(script.is_valid,':',costs_dry_run)
				var retcode = call(script.script_name, script)
				# When
				if script.script_name in wait_for_tasks \
						and retcode is GDScriptFunctionState:
					retcode = yield(retcode, "completed")
				if costs_dry_run:
					if retcode != CFConst.ReturnCode.CHANGED:
						can_all_costs_be_paid = false
					else:
						# We check for confirmation of optional cost tasks
						# only after checking that they are feasible
						# because there's no point in asking the player
						# about a task they cannot perform anyway.
						var confirm_return = CFUtils.confirm(
							script.script_definition,
							card_owner.card_name,
							script.script_name)
						if confirm_return is GDScriptFunctionState: # Still working.
							confirm_return = yield(confirm_return, "completed")
							# If the player chooses not to play an optional cost
							# We consider the whole cost dry run unsuccesful
							if not confirm_return:
								can_all_costs_be_paid = false
		else:
			 # If card has a script but it's null, it probably not coded yet. Just go on...
			print("[WARN] Found empty script. Ignoring...")
		# At the end of the task run, we loop back to the start, but of course
		# with one less item in our scripts_queue.
		run_next_script(card_owner,scripts_queue,script.subjects)


# Task for rotating cards
#
# Supports [KEY_IS_COST](SP#KEY_IS_COST).
#
# Requires the following keys:
# * [KEY_DEGREES](SP#KEY_DEGREES)
func rotate_card(script: ScriptTask) -> int:
	var retcode: int
	for card in script.subjects:
		# The last arg is the "check" flag.
		# Unfortunately Godot does not support passing named vars
		# (See https://github.com/godotengine/godot-proposals/issues/902)
		retcode = card.set_card_rotation(script.get_property(SP.KEY_DEGREES),
				false, true, costs_dry_run)
	return(retcode)


# Task for flipping cards
#
# Supports [KEY_IS_COST](SP#KEY_IS_COST).
#
# Requires the following keys:
# * [KEY_SET_FACEUP](SP#KEY_SET_FACEUP)
func flip_card(script: ScriptTask) -> int:
	var retcode: int
	for card in script.subjects:
		retcode = card.set_is_faceup(script.get_property(SP.KEY_SET_FACEUP),
				false,costs_dry_run)
	return(retcode)


# Task for moving card to a [CardContainer]
#
# Supports [KEY_IS_COST](SP#KEY_IS_COST).
#
# * [KEY_DEST_CONTAINER](SP#KEY_DEST_CONTAINER): [CardContainer]
# * (Optional) [KEY_DEST_INDEX](SP#KEY_DEST_INDEX): int
func move_card_to_container(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
	if costs_dry_run:
		if len(script.subjects) < script.requested_subjects:
			retcode = CFConst.ReturnCode.FAILED
	else:
		var dest_container: CardContainer = script.get_property(SP.KEY_DEST_CONTAINER)
		var dest_index = script.get_property(SP.KEY_DEST_INDEX)
		if str(dest_index) == SP.KEY_SUBJECT_INDEX_V_TOP:
			dest_index = -1
		elif str(dest_index) == SP.KEY_SUBJECT_INDEX_V_BOTTOM:
			dest_index = 0
		for card in script.subjects:
			card.move_to(dest_container,dest_index)
			yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
	return(retcode)


# Task for playing a card to the board directly.
#
# Supports [KEY_IS_COST](SP#KEY_IS_COST).
#
# Requires one of the following keys
# * [KEY_GRID_NAME](SP#KEY_GRID_NAME): String.
#	The board grid name to place the card.
# * [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION): Vector2.
#	The exact position to place the card.
func move_card_to_board(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
	if len(script.subjects) < script.requested_subjects:
		retcode = CFConst.ReturnCode.FAILED
	var grid_name: String = script.get_property(SP.KEY_GRID_NAME)
	if grid_name:
		var grid: BoardPlacementGrid
		var slot: BoardPlacementSlot
		grid = cfc.NMAP.board.get_grid(grid_name)
		if grid:
			# If there's more subjects to move than available slots
			# we don't move anything
			if script.subjects.size() > grid.count_available_slots() \
					and not grid.auto_extend:
				# If the found grid was full and not allowed to auto-extend,
				# we return FAILED for cost_checking purposes.
				retcode = CFConst.ReturnCode.FAILED
			elif not costs_dry_run:
				for card in script.subjects:
					slot = grid.find_available_slot()
					# We need a small delay, to allow a potential new slot to instance
					yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
					if slot:
						# Setting the highlight lets the move_to() method
						# Know we're moving into that slot
						card.move_to(cfc.NMAP.board, -1, slot)
		else:
			# If the named grid  was not found, we inform the developer.
			print_debug("WARNING: Script from card '"
					+ script.owner_card.card_name
					+ "' requested card move to grid '"
					+ grid_name + "', but no grid of such name was found.")
	else:
		var board_position = script.get_property(SP.KEY_BOARD_POSITION)
		var count = 0
		for card in script.subjects:
			# To avoid overlapping on the board, we spawn the cards
			# Next to each other.
			board_position.x += \
					count * CFConst.CARD_SIZE.x * CFConst.PLAY_AREA_SCALE.x
			count += 1
			# We assume cards moving to board want to be face-up
			if not costs_dry_run:
				card.move_to(cfc.NMAP.board, -1, board_position)
				yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
	return(retcode)

# Task from modifying tokens on a card
#
# Supports [KEY_IS_COST](SP#KEY_IS_COST).
#
# Requires the following keys:
# * [KEY_TOKEN_NAME](SP#KEY_TOKEN_NAME): String
# * [KEY_MODIFICATION](SP#KEY_MODIFICATION): int
# * (Optional) [KEY_SET_TO_MOD](SP#KEY_SET_TO_MOD): bool
func mod_tokens(script: ScriptTask) -> int:
	var retcode: int
	var modification: int
	var token_name: String = script.get_property(SP.KEY_TOKEN_NAME)
	if str(script.get_property(SP.KEY_MODIFICATION)) == SP.VALUE_RETRIEVE_INTEGER:
		modification = stored_integer
	elif "per_" in str(script.get_property(SP.KEY_MODIFICATION)):
		modification = ScriptObject.count_per(
				script.get_property(SP.KEY_MODIFICATION),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_MODIFICATION)))
	else:
		modification = script.get_property(SP.KEY_MODIFICATION)
	var set_to_mod: bool = script.get_property(SP.KEY_SET_TO_MOD)
	for card in script.subjects:
		retcode = card.tokens.mod_token(token_name,
				modification,set_to_mod,costs_dry_run)
	return(retcode)


# Task from creating a new card instance on the board
#
# Requires the following keys:
# * [KEY_SCENE_PATH](SP#KEY_SCENE_PATH): path to CardTemplate .tscn file
# * One of the following:
#	* [KEY_GRID_NAME](SP#KEY_GRID_NAME): String.
#	The board grid name to place the card.
#	* [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION): Vector2.
#	The exact position to place the card.
# * (Optional) [KEY_OBJECT_COUNT](SP#KEY_OBJECT_COUNT): int
func spawn_card(script: ScriptTask) -> void:
	var card: Card
	var count: int
	var card_scene: String = script.get_property(SP.KEY_SCENE_PATH)
	var grid_name: String = script.get_property(SP.KEY_GRID_NAME)
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
	elif "per_" in str(script.get_property(SP.KEY_OBJECT_COUNT)):
		count = ScriptObject.count_per(
				script.get_property(SP.KEY_OBJECT_COUNT),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_OBJECT_COUNT)))
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	if grid_name:
		var grid: BoardPlacementGrid
		var slot: BoardPlacementSlot
		grid = cfc.NMAP.board.get_grid(grid_name)
		if grid:
			for _iter in range(count):
				slot = grid.find_available_slot()
				# We need a small delay, to allow a potential new slot to instance
				yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
				if slot:
					card = load(card_scene).instance()
					cfc.NMAP.board.add_child(card)
					card.position = slot.rect_global_position
					card._placement_slot = slot
					slot.occupying_card = card
					card.state = Card.CardState.ON_PLAY_BOARD
	else:
		for iter in range(count):
			card = load(card_scene).instance()
			var board_position: Vector2 = script.get_property(SP.KEY_BOARD_POSITION)
			cfc.NMAP.board.add_child(card)
			card.position = board_position
			# If we're spawning more than 1 card, we place the extra ones
			# +1 card-length to the right each.
			card.position.x += \
					iter * CFConst.CARD_SIZE.x * CFConst.PLAY_AREA_SCALE.x
			card.state = Card.CardState.ON_PLAY_BOARD


# Task from shuffling a CardContainer
#
# Requires the following keys:
# * [KEY_DEST_CONTAINER](SP#KEY_DEST_CONTAINER): CardContainer
func shuffle_container(script: ScriptTask) -> void:
	var container: CardContainer = script.get_property(SP.KEY_DEST_CONTAINER)
	container.shuffle_cards()


# Task from making the owner card an attachment to another card
func attach_to_card(script: ScriptTask) -> void:
	for card in script.subjects:
		script.owner_card.attach_to_host(card)


# Task for attaching another card to the owner
func host_card(script: ScriptTask) -> void:
	# host_card can only ever have one subject
	var card: Card = script.subjects[0]
	card.attach_to_host(script.owner_card)


# Task for modifying a card's properties
#
# Requires the following values:
# * [KEY_MODIFY_PROPERTIES](SP#KEY_MODIFY_PROPERTIES)
func modify_properties(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.OK
	for card in script.subjects:
		var properties = script.get_property(SP.KEY_MODIFY_PROPERTIES)
		for property in properties:
			var ret_once = card.modify_property(
					property,
					properties[property],
					false,
					costs_dry_run)
			if ret_once == CFConst.ReturnCode.CHANGED:
				# We only need one of the properties requested to be
				# modified before we consider that we changed something.
				retcode = ret_once
	return(retcode)


# Requests the player input an integer, then stores it in a script-global
# variable to be used by any subsequent task
func ask_integer(script: ScriptTask) -> void:
	var integer_dialog = _ASK_INTEGER_SCENE.instance()
	# AskInteger tasks have to always provide a min and max value
	var minimum = script.get_property(SP.KEY_ASK_INTEGER_MIN)
	var maximum = script.get_property(SP.KEY_ASK_INTEGER_MAX)
	integer_dialog.prep(script.owner_card.card_name, minimum, maximum)
	# We have to wait until the player has finished selecting an option
	yield(integer_dialog,"popup_hide")
	stored_integer = integer_dialog.number
	# Garbage cleanup
	integer_dialog.queue_free()


# Adds a specified BoardPlacementGrid scene to the board at the specified position
#
# Requires the following keys:
# * [KEY_SCENE_PATH](SP#KEY_SCENE_PATH): path to BoardPlacementGrid .tscn file
# * (Optional) [KEY_GRID_NAME](SP#KEY_GRID_NAME): String.
# * [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION): Vector2.
# * (Optional) [KEY_OBJECT_COUNT](SP#KEY_OBJECT_COUNT): int
func add_grid(script: ScriptTask) -> void:
	var count: int
	var grid_name : String = script.get_property(SP.KEY_GRID_NAME)
	var board_position: Vector2 = script.get_property(SP.KEY_BOARD_POSITION)
	var grid_scene: String = script.get_property(SP.KEY_SCENE_PATH)
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	for iter in range(count):
		var grid: BoardPlacementGrid = load(grid_scene).instance()
		# A small delay to allow the instance to be added
		yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
		cfc.NMAP.board.add_child(grid)
		# If the grid name is empty, we use the predefined names in the scene.
		if grid_name != "":
			grid.name = grid_name
			grid.name_label.text = grid_name
		grid.rect_position = board_position
		# If we're spawning more than 1 grid, we place the extra ones
		# +1 card-width below, becase we assume they're spanwining with more
		# than 1 column.
		grid.rect_position.y += \
				iter * CFConst.CARD_SIZE.y * CFConst.PLAY_AREA_SCALE.y
