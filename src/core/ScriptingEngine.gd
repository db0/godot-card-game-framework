# This class contains all the functionality required to perform
# full rules enforcement on any card.
#
# The automation is based on [ScriptTask]s. Each such "task" performs a very specific
# manipulation of the board state, based on using existing functions
# in the object manipulated. Therefore each task function effectively provides a text-based API.
#
# This class is loaded by each card invidually during execution.
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
var trigger_details : Dictionary
var trigger_card: Card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Simply initiates the [run_next_script()](#run_next_script) loop
func _init(card_owner: Card,
		scripts_queue: Array,
		check_costs := false,
		_trigger_card: Card = null,
		_trigger_details = {}) -> void:
	trigger_details = _trigger_details
	trigger_card = _trigger_card
	costs_dry_run = check_costs
	run_next_script(card_owner,
			scripts_queue.duplicate())


# The main engine starts here.
# It receives array with all the tasks to execute,
# then turns each array element into a [ScriptTask] object and
# send it to the appropriate tasks.
func run_next_script(card_owner: Card,
		scripts_queue: Array,
		prev_subjects := []) -> void:
	var ta: TargetingArrow = card_owner.targeting_arrow
	if scripts_queue.empty():
#		print_debug(str(card_owner) + 'Scripting: All done!') # Debug
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
				stored_integer,
				trigger_card,
				trigger_details)
		# In case the task involves targetting, we need to wait on further
		# execution until targetting has completed
		cfc.NMAP.board.counters.temp_count_modifiers[self] = {
				"requesting_card": script.owner_card,
				"modifier": script.get_property(SP.KEY_TEMP_MOD_COUNTERS).duplicate()
			}
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
		elif not script.is_skipped and script.is_valid \
				and (not costs_dry_run
					or (costs_dry_run and script.get_property(SP.KEY_IS_COST))):
			#print(script.is_valid,':',costs_dry_run)
			for card in script.subjects:
				card.temp_properties_modifiers[self] = {
					"requesting_card": script.owner_card,
					"modifier": script.get_property(SP.KEY_TEMP_MOD_PROPERTIES)\
							.duplicate()
				}
			var retcode = call(script.script_name, script)
			if retcode is GDScriptFunctionState:
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
		# If a cost script is not valid
		# (such as because the subjects cannot be matched)
		# Then we consider the costs cannot be paid.
		# However is the task was merely skipped (because filters didn't match)
		# we don't consider the whole script failed
		elif not script.is_valid and script.get_property(SP.KEY_IS_COST):
			can_all_costs_be_paid = false
		# At the end of the task run, we loop back to the start, but of course
		# with one less item in our scripts_queue.
		cfc.NMAP.board.counters.temp_count_modifiers.erase(self)
		for card in script.subjects:
			card.temp_properties_modifiers.erase(self)
		run_next_script(card_owner,scripts_queue,script.subjects)


# Task for rotating cards
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* [KEY_DEGREES](SP#KEY_DEGREES)
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
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* [KEY_SET_FACEUP](SP#KEY_SET_FACEUP)
func flip_card(script: ScriptTask) -> int:
	var retcode: int
	for card in script.subjects:
		retcode = card.set_is_faceup(script.get_property(SP.KEY_SET_FACEUP),
				false,costs_dry_run)
	return(retcode)


# Task for viewing face-down cards
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
func view_card(script: ScriptTask) -> int:
	var retcode: int
	for card in script.subjects:
		retcode = card.set_is_viewed(true)
	return(retcode)


# Task for moving card to a [CardContainer]
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* [KEY_DEST_CONTAINER](SP#KEY_DEST_CONTAINER)
# * Optionally uses the following keys:
#	* [KEY_DEST_INDEX](SP#KEY_DEST_INDEX)
#	* [KEY_SUBJECT_INDEX](SP#KEY_SUBJECT_INDEX)
#	* [KEY_SRC_CONTAINER](SP#KEY_SRC_CONTAINER)
func move_card_to_container(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
	if not costs_dry_run:
		var dest_container: CardContainer = script.get_property(SP.KEY_DEST_CONTAINER)
		var dest_index = script.get_property(SP.KEY_DEST_INDEX)
		if str(dest_index) == SP.KEY_SUBJECT_INDEX_V_TOP:
			dest_index = -1
		elif str(dest_index) == SP.KEY_SUBJECT_INDEX_V_BOTTOM:
			dest_index = 0
		# If we're placing in a random index, we're simply choosing a random
		# card in the container, and placing in its position
		elif str(dest_index) == SP.KEY_SUBJECT_INDEX_V_RANDOM:
			dest_index = dest_container.get_card_index(dest_container.get_random_card())
		for card in script.subjects:
			# We don't allow to draw more cards than the hand size
			# But we don't consider it a failed cost (as most games allow you
			# to try and draw more cards when you're full but just won't draw any)
			card.move_to(dest_container,dest_index, null, true)
			yield(script.owner_card.get_tree().create_timer(0.05), "timeout")
	return(retcode)


# Task for playing a card to the board directly.
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Requires the following keys
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* One of the following:
#		* [KEY_GRID_NAME](SP#KEY_GRID_NAME)
#		* [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION)
# * Optionally uses the following keys:
#	* [KEY_SUBJECT_INDEX](SP#KEY_SUBJECT_INDEX)
#	* [KEY_SRC_CONTAINER](SP#KEY_SRC_CONTAINER)
func move_card_to_board(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
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
						card.move_to(cfc.NMAP.board, -1, slot, true)
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
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Can be affected by [Alterants](SP#KEY_ALTERANTS).
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* [KEY_TOKEN_NAME](SP#KEY_TOKEN_NAME)
#	* [KEY_MODIFICATION](SP#KEY_MODIFICATION)
# * Optionally uses the following keys:
#	* [KEY_SET_TO_MOD](SP#KEY_SET_TO_MOD)
func mod_tokens(script: ScriptTask) -> int:
	var retcode: int
	var modification: int
	var alteration = 0
	var token_name: String = script.get_property(SP.KEY_TOKEN_NAME)
	if str(script.get_property(SP.KEY_MODIFICATION)) == SP.VALUE_RETRIEVE_INTEGER:
		modification = stored_integer
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_MODIFICATION)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_MODIFICATION),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_MODIFICATION)),
				null,
				script.subjects)
		modification = per_msg.found_things
	else:
		modification = script.get_property(SP.KEY_MODIFICATION)
	var set_to_mod: bool = script.get_property(SP.KEY_SET_TO_MOD)
	if not set_to_mod:
		alteration = _check_for_alterants(script, modification)
		if alteration is GDScriptFunctionState:
			alteration = yield(alteration, "completed")
	for card in script.subjects:
		retcode = card.tokens.mod_token(token_name,
				modification + alteration,set_to_mod,costs_dry_run)
	return(retcode)


# Task from creating a new card instance on the board
# * Can be affected by [Alterants](SP#KEY_ALTERANTS)
# * Requires the following keys:
#	* [KEY_SCENE_PATH](SP#KEY_SCENE_PATH): path to a Card .tscn file
#	* One of the following:
#		* [KEY_GRID_NAME](SP#KEY_GRID_NAME)
#		* [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION)
# * Optionally uses the following keys:
#	* [KEY_OBJECT_COUNT](SP#KEY_OBJECT_COUNT)
func spawn_card(script: ScriptTask) -> void:
	var card: Card
	var count: int
	var alteration = 0
	var card_scene: String = script.get_property(SP.KEY_SCENE_PATH)
	var grid_name: String = script.get_property(SP.KEY_GRID_NAME)
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_OBJECT_COUNT)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_OBJECT_COUNT),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_OBJECT_COUNT)),
				null,
				script.subjects)
		count = per_msg.found_things
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	alteration = _check_for_alterants(script, count)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	if grid_name:
		var grid: BoardPlacementGrid
		var slot: BoardPlacementSlot
		grid = cfc.NMAP.board.get_grid(grid_name)
		if grid:
			for _iter in range(count + alteration):
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
		for iter in range(count + alteration):
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
# * Requires the following keys:
#	* [KEY_DEST_CONTAINER](SP#KEY_DEST_CONTAINER)
func shuffle_container(script: ScriptTask) -> void:
	var container: CardContainer = script.get_property(SP.KEY_DEST_CONTAINER)
	container.shuffle_cards()


# Task from making the owner card an attachment to the subject card.
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
func attach_to_card(script: ScriptTask) -> void:
	for card in script.subjects:
		script.owner_card.attach_to_host(card)


# Task from making the subject card an attachment to the owner card.
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
func host_card(script: ScriptTask) -> void:
	# host_card can only ever use one subject
	var card: Card = script.subjects[0]
	card.attach_to_host(script.owner_card)


# Task for modifying a card's properties
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
#	* [KEY_MODIFY_PROPERTIES](SP#KEY_MODIFY_PROPERTIES)
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
			if ret_once == CFConst.ReturnCode.FAILED:
				retcode = ret_once
			elif ret_once == CFConst.ReturnCode.CHANGED\
					and retcode != CFConst.ReturnCode.FAILED:
				# We only need one of the properties requested to be
				# modified before we consider that we changed something.
				# But only if any of the other modifications hasn't failed
				retcode = ret_once
	return(retcode)


# Requests the player input an integer, then stores it in a script-global
# variable to be used by any subsequent task
# * Requires the following keys:
#	* [KEY_ASK_INTEGER_MIN](SP#KEY_ASK_INTEGER_MIN)
#	* [KEY_ASK_INTEGER_MAX](SP#KEY_ASK_INTEGER_MAX)
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
# * Requires the following keys:
#	* [KEY_SCENE_PATH](SP#KEY_SCENE_PATH): path to BoardPlacementGrid .tscn file
#	* One of the following:
#		* [KEY_BOARD_POSITION](SP#KEY_BOARD_POSITION)
#		* [KEY_GRID_NAME](SP#KEY_GRID_NAME)
# * Optionally uses the following keys:
#	* [KEY_OBJECT_COUNT](SP#KEY_OBJECT_COUNT)
#	* [KEY_GRID_NAME](SP#KEY_GRID_NAME)
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

# Task for modifying a a counter.
# If this task is specified, the variable [counters](Board#counters) **has** to be set
# inside the board script
# * Supports [KEY_IS_COST](SP#KEY_IS_COST).
# * Can be affected by [Alterants](SP#KEY_ALTERANTS)
# * Requires the following keys:
#	* [KEY_COUNTER_NAME](SP#KEY_COUNTER_NAME)
#	* [KEY_MODIFICATION](SP#KEY_MODIFICATION)
# * Optionally uses the following keys:
#	* [KEY_SET_TO_MOD](SP#KEY_SET_TO_MOD)
func mod_counter(script: ScriptTask) -> int:
	var counter_name: String = script.get_property(SP.KEY_COUNTER_NAME)
	var modification: int
	var alteration = 0
	if str(script.get_property(SP.KEY_MODIFICATION)) == SP.VALUE_RETRIEVE_INTEGER:
		modification = stored_integer
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_MODIFICATION)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_MODIFICATION),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_MODIFICATION)),
				null,
				script.subjects)
		modification = per_msg.found_things
	else:
		modification = script.get_property(SP.KEY_MODIFICATION)
	var set_to_mod: bool = script.get_property(SP.KEY_SET_TO_MOD)
	# We do not not modify
	if not set_to_mod:
		alteration = _check_for_alterants(script, modification)
		if alteration is GDScriptFunctionState:
			alteration = yield(alteration, "completed")
	var retcode: int = cfc.NMAP.board.counters.mod_counter(
			counter_name,
			modification + alteration,
			set_to_mod,
			costs_dry_run,
			script.owner_card)
	return(retcode)


# Task for executing scripts on subject cards.
# * Supports [KEY_IS_COST](SP#KEY_IS_COST). If it is set, the cost check
#	will fail, if any of the target card's cost checks also fail.
# * Requires the following keys:
#	* [KEY_SUBJECT](SP#KEY_SUBJECT)
# * Optionally uses the following keys:
#	* [KEY_REQUIRE_EXEC_STATE](SP#KEY_REQUIRE_EXEC_STATE)
#	* [KEY_EXEC_TEMP_MOD_PROPERTIES](SP#KEY_EXEC_TEMP_MOD_PROPERTIES)
#	* [KEY_EXEC_TEMP_MOD_COUNTERS](SP#KEY_EXEC_TEMP_MOD_COUNTERS)
#	* [KEY_EXEC_TRIGGER](SP#KEY_EXEC_TRIGGER)
func execute_scripts(script: ScriptTask) -> int:
	var retcode : int = CFConst.ReturnCode.CHANGED
	# If your subject is "self" make sure you know what you're doing
	# or you might end up in an inifinite loop
	for card in script.subjects:
		var requested_exec_state = script.get_property(SP.KEY_REQUIRE_EXEC_STATE)
		# If not specific exec_state has been requested
		# we execute whatever scripts of the state the card is currently in.
		if not requested_exec_state or requested_exec_state == card.get_state_exec():
			var sceng = card.execute_scripts(
					script.owner_card,
					script.get_property(SP.KEY_EXEC_TRIGGER),
					{}, costs_dry_run)
			# We make sure we wait until the execution is finished
			# before cleaning out the temp properties/counters
			if sceng is GDScriptFunctionState:
				sceng = yield(sceng, "completed")
			# Executing scripts on other cards need to noy only check their
			# own costs are possible, but the target cards as well
			# but only if the subject is explictly specified, such as
			# target. We don't want to play a card which will not affect its
			# explicit target, but we do want to be able to play a card
			# which, for example, tries to affect all cards on the table,
			# but none of them is actually affected.
			if sceng and not sceng.can_all_costs_be_paid\
					and not script.get_property(SP.KEY_SUBJECT)\
					in [SP.KEY_SUBJECT_V_BOARDSEEK, SP.KEY_SUBJECT_V_TUTOR]:
				retcode = CFConst.ReturnCode.FAILED
	return(retcode)

# Initiates a seek through the table to see if there's any cards
# which have scripts which modify the intensity of the current task.
func _check_for_alterants(script: ScriptTask, value: int) -> int:
	var alteration = CFScriptUtils.get_altered_value(
		script.owner_card,
		script.script_name,
		script.script_definition,
		value)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	return(alteration.value_alteration)

