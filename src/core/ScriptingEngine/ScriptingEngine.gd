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
# Emited when each task is completed.
signal single_task_completed(task)


var run_type : int = CFInt.RunType.NORMAL

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
var scripts_queue: Array
# Each ScriptingEngine execution gets an ID.
# This can be used by games to be able to take a "snapshot" of the changes
# in the board state as the script would execute and therefore know what the 
# state of the board would be mid-execution, even during dry-runs
var snapshot_id : float = 0


# Simply initiates the [run_next_script()](#run_next_script) loop
func _init(state_scripts: Array,
		owner,
		trigger_object: Node,
		trigger_details: Dictionary) -> void:
	for t in state_scripts:
		# We do a duplicate to allow repeat to modify tasks without danger.
		var task: Dictionary = t.duplicate(true)
		# This is the only script property which we use outside of the
		# ScriptTask object. The repeat property duplicates the whole task
		# definition in multiple tasks
		var repeat = task.get(SP.KEY_REPEAT, 1)
		if SP.VALUE_PER in str(repeat):
			var per_msg = perMessage.new(
					repeat,
					owner,
					task.get(repeat),
					trigger_object,
					[],
					[])
			repeat = per_msg.found_things
		# If there are no targets to repeat,  and the task was targetting
		# It means it might have fired off of a dragging action, and we want to avoid
		# it triggering when the player tries to drag it from hand and doing nothing.
		if repeat == 0 \
				and cfc.card_drag_ongoing == owner\
				and task.get(SP.KEY_SUBJECT) == SP.KEY_SUBJECT_V_TARGET\
				and (task.get(SP.KEY_IS_COST) or task.get(SP.KEY_NEEDS_SUBJECT)):
			can_all_costs_be_paid = false
		for iter in range(repeat):
			# In case it's a targeting task, we assume we don't want to
			# spawn X targeting arrows at the same time, so we convert
			# all subsequent repeats into "previous" targets
			if iter > 0 and task.has("subject") and task["subject"] == "target":
				task["subject"] = "previous"
			var script_task := ScriptTask.new(
					owner,
					task,
					trigger_object,
					trigger_details)
			scripts_queue.append(script_task)

# This flag will be true if we're attempting to find if the card
# has costs that need to be paid, before the effects take place.
func costs_dry_run() -> bool:
	if run_type == CFInt.RunType.COST_CHECK:
		return(true)
	else:
		return(false)


# The main engine starts here.
# It receives array with all the tasks to execute,
# then turns each array element into a [ScriptTask] object and
# send it to the appropriate tasks.
func execute(_run_type := CFInt.RunType.NORMAL) -> void:
	snapshot_id = rand_range(1,10000000)
	all_tasks_completed = false
	run_type = _run_type
	var prev_subjects := []
	for task in scripts_queue:
		# Failsafe for GUT tearing down while Sceng is running
		if not cfc.NMAP.has("board") or not is_instance_valid(cfc.NMAP.board): return
		# We put it into another variable to allow Static Typing benefits
		var script: ScriptTask = task
		if ((run_type == CFInt.RunType.COST_CHECK and not script.is_cost and not script.needs_subject)
				or (run_type == CFInt.RunType.ELSE and not script.is_else)
				or (run_type != CFInt.RunType.ELSE and script.is_else)):
			continue
		# We store the temp modifiers to counters, so that things like
		# info during targetting can take them into account
		cfc.NMAP.board.counters.set_temp_counter_modifiers(
			self, task, script.owner, _retrieve_temp_modifiers(script,"counters"))
		# This is provisionally stored for games which need to use this
		# information before card subjects have been selected.
		cfc.card_temp_property_modifiers[self] = {
			"requesting_object": script.owner,
			"modifier": _retrieve_temp_modifiers(script, "properties")
		}
		if not script.is_primed:
			# Since the costs are processed serially, we can mark some costs
			# to only be paid, if all previous costs have been paid as well.
			# This allows us to avoid opening popup windows for cost selection
			# when previous costs have not been achieved (e.g. targeting)
			if script.get_property(SP.KEY_ABORT_ON_COST_FAILURE) and not can_all_costs_be_paid:
				continue
			# If we have requested to use the previous target,
			# but the subject_array is empty, we check if
			# subject available in the next task and try to use that instead.
			# This allows a "previous" subject task, to be placed before
			# the task which requires a target, as long as the targetting task
			# "is_cost".
			# This is useful for example, when the targeting task would move
			# The subject to another pile but we want to check (#SUBJECT_PARENT)
			# against the parent it had before it was moved.
			if script.get_property(SP.KEY_SUBJECT) == SP.KEY_SUBJECT_V_PREVIOUS\
					and prev_subjects.size() == 0:
				var current_index := scripts_queue.find(task)
				var next_task: ScriptTask =  scripts_queue[current_index + 1]
				if next_task.subjects.size() > 0:
					prev_subjects = next_task.subjects
			script.prime(prev_subjects,run_type,stored_integer)
			# In case the task involves targetting, we need to wait on further
			# execution until targetting has completed
			if not script.is_primed:
				yield(script,"primed")
		if script.is_primed:
			_pre_task_exec(script)
			#print("Scripting Subjects: " + str(script.subjects)) # Debug
			if script.script_name == "custom_script"\
					and not script.is_skipped and script.is_valid:
				# This class contains the customly defined scripts for each
				# card.
				var custom := CustomScripts.new(costs_dry_run())
				custom.custom_script(script)
			elif not script.is_skipped and script.is_valid\
					and (not costs_dry_run()
						or (costs_dry_run() and script.is_cost)):
				#print(script.is_valid,':',costs_dry_run())
				for card in script.subjects:
					if not is_instance_valid(card):
						script.subjects.erase(card)
						continue
					card.temp_properties_modifiers[self] = {
						"requesting_object": script.owner,
						"modifier": _retrieve_temp_modifiers(script, "properties")
					}
				var retcode = call(script.script_name, script)
				if retcode is GDScriptFunctionState:
					retcode = yield(retcode, "completed")
				# We set the previous subjects only after the execution, because some tasks
				# might change the previous subjects for the future tasks
				if not script.get_property(SP.KEY_PROTECT_PREVIOUS):
					prev_subjects = script.subjects
				if costs_dry_run():
					if retcode != CFConst.ReturnCode.CHANGED:
						can_all_costs_be_paid = false
					else:
						# We check for confirmation of optional cost tasks
						# only after checking that they are feasible
						# because there's no point in asking the player
						# about a task they cannot perform anyway.
						var confirm_return = script.check_confirm()
						if confirm_return is GDScriptFunctionState: # Still working.
							yield(confirm_return, "completed")
						if not script.is_accepted:
							can_all_costs_be_paid = false
			# If a cost script is not valid
			# (such as because the subjects cannot be matched)
			# Then we consider the costs cannot be paid.
			# However is the task was merely skipped (because filters didn't match)
			# we don't consider the whole script failed.
			# This allows us to have conditional costs based on the board state
			# which will not abort the overall script.
			elif not script.is_valid and script.is_cost:
				can_all_costs_be_paid = false
			# This allows a skipped board state filter such as filter_per_counter
			# placed in an is_cost task, to block all other tasks.
			elif script.is_skipped\
					and script.get_property(SP.KEY_FAIL_COST_ON_SKIP)\
					and script.is_cost:
				can_all_costs_be_paid = false
			# This allows a script which is not a cost to be evaluated
			# along with the costs, but only for having subjects.
			elif not script.is_valid\
					and script.needs_subject:
				can_all_costs_be_paid = false
			# If this is a dry run and the script needs a target
			# we need to set the previous_subjects now
			# because these are typically only set before the script executes.
			elif costs_dry_run() \
					and script.needs_subject \
					and not script.get_property(SP.KEY_PROTECT_PREVIOUS):
				prev_subjects = script.subjects
			# At the end of the task run, we loop back to the start, but of course
			# with one less item in our scripts_queue.
			emit_signal("single_task_completed", task)
			cfc.card_temp_property_modifiers.erase(self)
			for card in script.subjects:
				# Some cards might be removed from the game after their execution
				if is_instance_valid(card):
					card.temp_properties_modifiers.erase(self)
#	print_debug(str(card_owner) + 'Scripting: All done!') # Debug
	all_tasks_completed = true
	emit_signal("tasks_completed")
	# checking costs on multiple targeted cards in the same script,
	# is not supported at the moment due to the exponential complexities
#	elif costs_dry_run() and ta.target_dry_run_card and \
#				scripts_queue[0].get(SP.KEY_SUBJECT) == "target":
#			scripts_queue.pop_front()
#			run_next_script(card_owner,
#					scripts_queue,prev_subjects)


# Task for rotating cards
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* [KEY_DEGREES](ScriptProperties#KEY_DEGREES)
func rotate_card(script: ScriptTask) -> int:
	var retcode: int
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	for card in script.subjects:
		# The last arg is the "check" flag.
		# Unfortunately Godot does not support passing named vars
		# (See https://github.com/godotengine/godot-proposals/issues/902)
		retcode = card.set_card_rotation(script.get_property(SP.KEY_DEGREES),
				false, true, costs_dry_run(), tags)
	return(retcode)


# Task for flipping cards
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* [KEY_SET_FACEUP](ScriptProperties#KEY_SET_FACEUP)
func flip_card(script: ScriptTask) -> int:
	var retcode: int
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	for card in script.subjects:
		retcode = card.set_is_faceup(script.get_property(SP.KEY_SET_FACEUP),
				false,costs_dry_run(), tags)
	return(retcode)


# Task for viewing face-down cards
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
func view_card(script: ScriptTask) -> int:
	var retcode: int
	for card in script.subjects:
		retcode = card.set_is_viewed(true)
	return(retcode)


# Task for moving card to a [CardContainer]
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* [KEY_DEST_CONTAINER](ScriptProperties#KEY_DEST_CONTAINER)
# * Optionally uses the following keys:
#	* [KEY_DEST_INDEX](ScriptProperties#KEY_DEST_INDEX)
#	* [KEY_SUBJECT_INDEX](ScriptProperties#KEY_SUBJECT_INDEX)
#	* [KEY_SRC_CONTAINER](ScriptProperties#KEY_SRC_CONTAINER)
func move_card_to_container(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
	if not costs_dry_run():
		# We inject the tags from the script into the tags sent by the signal
		var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
		var dest_container: CardContainer = cfc.NMAP[script.get_property(SP.KEY_DEST_CONTAINER).to_lower()]
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
			card.move_to(dest_container,dest_index, null, tags)
			yield(script.owner.get_tree().create_timer(0.05), "timeout")
	return(retcode)


# Task for playing a card to the board directly.
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Requires the following keys
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* One of the following:
#		* [KEY_GRID_NAME](ScriptProperties#KEY_GRID_NAME)
#		* [KEY_BOARD_POSITION](ScriptProperties#KEY_BOARD_POSITION)
# * Optionally uses the following keys:
#	* [KEY_SUBJECT_INDEX](ScriptProperties#KEY_SUBJECT_INDEX)
#	* [KEY_SRC_CONTAINER](ScriptProperties#KEY_SRC_CONTAINER)
func move_card_to_board(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.CHANGED
	var grid_name: String = script.get_property(SP.KEY_GRID_NAME)
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
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
			elif not costs_dry_run():
				for card in script.subjects:
					slot = grid.find_available_slot()
					# We need a small delay, to allow a potential new slot to instance
					yield(script.owner.get_tree().create_timer(0.05), "timeout")
					if slot:
						# Setting the highlight lets the move_to() method
						# Know we're moving into that slot
						card.move_to(cfc.NMAP.board, -1, slot, tags)
		else:
			# If the named grid  was not found, we inform the developer.
			print_debug("WARNING: Script from card '"
					+ script.owner.canonical_name
					+ "' requested card move to grid '"
					+ grid_name + "', but no grid of such name was found.")
	else:
		var board_position = script.get_property(SP.KEY_BOARD_POSITION)
		var count = 0
		for card in script.subjects:
			# To avoid overlapping on the board, we spawn the cards
			# Next to each other.
			board_position.x += \
					count * card.canonical_size.x * card.play_area_scale
			count += 1
			# We assume cards moving to board want to be face-up
			if not costs_dry_run():
				card.move_to(cfc.NMAP.board, -1, board_position, tags)
				yield(script.owner.get_tree().create_timer(0.05), "timeout")
	return(retcode)


# Task from modifying tokens on a card
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Can be affected by [Alterants](ScriptProperties#KEY_ALTERANTS).
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* [KEY_TOKEN_NAME](ScriptProperties#KEY_TOKEN_NAME)
#	* [KEY_MODIFICATION](ScriptProperties#KEY_MODIFICATION)
# * Optionally uses the following keys:
#	* [KEY_SET_TO_MOD](ScriptProperties#KEY_SET_TO_MOD)
func mod_tokens(script: ScriptTask) -> int:
	var retcode: int
	var modification: int
	var alteration = 0
	var token_name: String = script.get_property(SP.KEY_TOKEN_NAME)
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	if str(script.get_property(SP.KEY_MODIFICATION)) == SP.VALUE_RETRIEVE_INTEGER:
		modification = stored_integer
		if script.get_property(SP.KEY_IS_INVERTED):
			modification *= -1
		modification += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_MODIFICATION)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_MODIFICATION),
				script.owner,
				script.get_property(script.get_property(SP.KEY_MODIFICATION)),
				null,
				script.subjects,
				script.prev_subjects)
		modification = per_msg.found_things
	else:
		modification = script.get_property(SP.KEY_MODIFICATION)
	var set_to_mod: bool = script.get_property(SP.KEY_SET_TO_MOD)
	if not set_to_mod:
		alteration = _check_for_alterants(script, modification)
		if alteration is GDScriptFunctionState:
			alteration = yield(alteration, "completed")
	var token_diff := 0
	for card in script.subjects:
		var current_tokens: int
		# If we're storing the integer, we want to store the difference
		# cumulative difference between the current and modified tokens
		# among all the cards
		# If if se set tokens to 1, and one card had 3 tokens,
		# while another had 0
		# The total stored integer would be -1
		# This allows us to do an effect like
		# Remove all Poison tokens from all cards, draw a card for each token removed.
		if script.get_property(SP.KEY_STORE_INTEGER):
			current_tokens = card.tokens.get_token_count(token_name)
			if set_to_mod:
				token_diff += modification + alteration - current_tokens
			elif current_tokens + modification + alteration < 0:
				token_diff += -current_tokens
			else:
				token_diff = modification + alteration
		retcode = card.tokens.mod_token(token_name,
				modification + alteration,set_to_mod,costs_dry_run(), tags)
	if script.get_property(SP.KEY_STORE_INTEGER):
		stored_integer = token_diff
	return(retcode)


# Task from creating a new card instance on the board
# * Can be affected by [Alterants](ScriptProperties#KEY_ALTERANTS)
# * Requires the following keys:
#	* [KEY_CARD_NAME](ScriptProperties#KEY_CARD_NAME): name of the Card as per card definitions
#	* One of the following:
#		* [KEY_GRID_NAME](ScriptProperties#KEY_GRID_NAME)
#		* [KEY_BOARD_POSITION](ScriptProperties#KEY_BOARD_POSITION)
# * Optionally uses the following keys:
#	* [KEY_OBJECT_COUNT](ScriptProperties#KEY_OBJECT_COUNT)
func spawn_card(script: ScriptTask) -> void:
	var card: Card
	var count: int
	var alteration = 0
	var canonical_name: String = script.get_property(SP.KEY_CARD_NAME)
	var grid_name: String = script.get_property(SP.KEY_GRID_NAME)
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
		if script.get_property(SP.KEY_IS_INVERTED):
			count *= -1
		count += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_OBJECT_COUNT)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_OBJECT_COUNT),
				script.owner,
				script.get_property(script.get_property(SP.KEY_OBJECT_COUNT)),
				null,
				script.subjects,
				script.prev_subjects)
		count = per_msg.found_things
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	alteration = _check_for_alterants(script, count)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	var spawned_cards := []
	if grid_name:
		var grid: BoardPlacementGrid
		var slot: BoardPlacementSlot
		grid = cfc.NMAP.board.get_grid(grid_name)
		if grid:
			for _iter in range(count + alteration):
				slot = grid.find_available_slot()
				# We need a small delay, to allow a potential new slot to instance
				yield(script.owner.get_tree().create_timer(0.05), "timeout")
				if slot:
					card = cfc.instance_card(canonical_name)
					cfc.NMAP.board.add_child(card)
					card.position = slot.rect_global_position
					card._placement_slot = slot
					slot.occupying_card = card
					card.state = Card.CardState.ON_PLAY_BOARD
					spawned_cards.append(card)
	else:
		for iter in range(count + alteration):
			card = cfc.instance_card(canonical_name)
			var board_position: Vector2 = script.get_property(SP.KEY_BOARD_POSITION)
			cfc.NMAP.board.add_child(card)
			card.position = board_position
			# If we're spawning more than 1 card, we place the extra ones
			# +1 card-length to the right each.
			card.position.x += \
					iter * card.canonical_size.x * card.play_area_scale
			card.state = Card.CardState.ON_PLAY_BOARD
			card.set_to_idle()
			spawned_cards.append(card)
	# We set the spawned cards as the subjects, so that they can be
	# used by other followup scripts
	script.subjects = spawned_cards
	# Adding a small delay to allow the cards to finish instancing and setting their
	# properties
	yield(script.owner.get_tree().create_timer(0.1), "timeout")


# Task from creating a new card instance in a CardContainer
# * Can be affected by [Alterants](ScriptProperties#KEY_ALTERANTS)
# * Requires the following keys:
#	* One of the following:
#		* [KEY_CARD_NAME](ScriptProperties#KEY_CARD_NAME): name of the Card as per card definitions
#		* [KEY_CARD_FILTERS](ScriptProperties#KEY_CARD_FILTERS): A dictionary to pass to CardFilter to filter possible cards from the card pool
#			if KEY_CARD_FILTERS is specified then the following key has to also be specified:
#			* if [KEY_SELECTION_CHOICES_AMOUNT](ScriptProperties#KEY_SELECTION_CHOICES_AMOUNT): How to select cards based on the specified filters
#	* [KEY_DEST_CONTAINER](ScriptProperties#KEY_DEST_CONTAINER): The container in which to place the created card
# * Optionally uses the following keys:
#	* [KEY_OBJECT_COUNT](ScriptProperties#KEY_OBJECT_COUNT)
func spawn_card_to_container(script: ScriptTask) -> void:
	var card: Card
	var count: int
	var alteration = 0
	var canonical_name = script.get_property(SP.KEY_CARD_NAME)
	var card_filters = script.get_property(SP.KEY_CARD_FILTERS)
	if card_filters:
		var selection_amount = script.get_property(SP.KEY_SELECTION_CHOICES_AMOUNT)
		var compiled_filters := []
		for filter_props in card_filters:
			var card_filter := CardFilter.new(
					filter_props.property,
					filter_props.value,
					filter_props.get("comparison", "eq"),
					filter_props.get("compare_int_as_str", false))
			compiled_filters.append(card_filter)
		var filtered_cards : Array = cfc.ov_utils.filter_card_pool(compiled_filters)
		# If we found less potential cards than the amount to select from, we adjust
		if filtered_cards.size() < selection_amount:
			selection_amount = filtered_cards.size()
		CFUtils.shuffle_array(filtered_cards)
		if filtered_cards.size() == 0:
			printerr("WARN: Cannot find any cards to spawn with the selected filter for script:\n" + str(script.script_definition))
			return
		if selection_amount < 0:
			 return
		if selection_amount == 1:
			canonical_name = filtered_cards[0]
		else:
			filtered_cards = filtered_cards.slice(0,selection_amount - 1)
			var select_return = cfc.ov_utils.select_card(
					filtered_cards, 1, 'min', false, cfc.NMAP.board)
			if select_return is GDScriptFunctionState: # Still working.
				select_return = yield(select_return, "completed")
			if typeof(select_return) == TYPE_ARRAY:
				canonical_name = select_return[0]
			else:
				return
	var dest_container: CardContainer = cfc.NMAP[script.get_property(SP.KEY_DEST_CONTAINER).to_lower()]
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
		if script.get_property(SP.KEY_IS_INVERTED):
			count *= -1
		count += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_OBJECT_COUNT)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_OBJECT_COUNT),
				script.owner,
				script.get_property(script.get_property(SP.KEY_OBJECT_COUNT)),
				null,
				script.subjects,
				script.prev_subjects)
		count = per_msg.found_things
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	alteration = _check_for_alterants(script, count)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	var spawned_cards := []
	for iter in range(count + alteration):
		card = cfc.instance_card(canonical_name)
		if not script.get_property(SP.KEY_IMMEDIATE_PLACEMENT):
			cfc.NMAP.board.add_child(card)
			card.scale = Vector2(0.1,0.1)
			if 'rect_global_position' in script.owner:
				card.global_position = script.owner.rect_global_position
			else:
				card.global_position = script.owner.global_position
			card.global_position.x += \
					iter * CFConst.CARD_SIZE.x * 0.2
			card.spawn_destination = dest_container
			card.state = Card.CardState.MOVING_TO_SPAWN_DESTINATION
		else:
			dest_container.add_child(card)
			card.set_to_idle()
		# We set the drawn cards as the subjects, so that they can be
		# used by other followup scripts
		yield(cfc.get_tree().create_timer(0.2), "timeout")
		spawned_cards.append(card)
	script.subjects = spawned_cards

# Task from shuffling a CardContainer
# * Requires the following keys:
#	* [KEY_DEST_CONTAINER](ScriptProperties#KEY_DEST_CONTAINER)
func shuffle_container(script: ScriptTask) -> void:
	var container: CardContainer = cfc.NMAP[script.get_property(SP.KEY_DEST_CONTAINER).to_lower()]
	while container.are_cards_still_animating():
		yield(container.get_tree().create_timer(0.2), "timeout")
	container.shuffle_cards()
	# If there's no shuffle aniumation, we will get stuck if we yield.
	if container.is_in_group("piles") and container.shuffle_style != CFConst.ShuffleStyle.NONE:
		yield(container, "shuffle_completed")


# Task from making the owner card an attachment to the subject card.
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
func attach_to_card(script: ScriptTask) -> void:
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	for card in script.subjects:
		script.owner.attach_to_host(card, false, tags)


# Task from making the subject card an attachment to the owner card.
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
func host_card(script: ScriptTask) -> void:
	# host_card can only ever use one subject
	var card: Card = script.subjects[0]
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	card.attach_to_host(script.owner, false, tags)


# Task for modifying a card's properties
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
#	* [KEY_MODIFY_PROPERTIES](ScriptProperties#KEY_MODIFY_PROPERTIES)
func modify_properties(script: ScriptTask) -> int:
	var retcode: int = CFConst.ReturnCode.OK
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	for card in script.subjects:
		var properties = script.get_property(SP.KEY_MODIFY_PROPERTIES)
		for property in properties:
			var alteration = null
			# We can only alter numerical properties
			var modification : int
			if property in CardConfig.PROPERTIES_NUMBERS:
				var new_value : int
				# We need to calculate what the future value would be, to pass
				# it to the alterant as the modification properties
				# As we might have alterants that modify values increasing
				# or decreasing specifically.
				if typeof(properties[property]) == TYPE_STRING:
					# A per value can also be in the form of
					# "+per_..." which signifies adjusting the existing value
					# by the value of the per calculation
					if SP.VALUE_PER in properties[property]:
						var per_msg = perMessage.new(
								# We remove any plus sign which marks
								# adjustment of property
								properties[property].lstrip('+'),
								script.owner,
								# This retrieves the dictionary named after the
								# per_value
								# -per is not supported!
								script.get_property(properties[property].lstrip('+')),
								null,
								script.subjects,
								script.prev_subjects)
						modification = per_msg.found_things
						# We cannot check for +/- using .is_valid_integer() because
						# the value might be something like '+per_counter'
						if '+' in properties[property] or '-' in properties[property]:
							new_value = card.get_property(property)\
									+ modification
						else:
							new_value = modification
					# if the value is not a per, then it might be a +/- adjustemnt
					# which we only handle if the current card property is an actual integer
					elif properties[property].is_valid_integer()\
							and typeof(card.get_property(property)) == TYPE_INT:
						modification = int(properties[property])
						new_value = card.get_property(property) + modification
					# If the string in the modification is not a valid integer
					# Then there's no point in checking for alterants,
					# and we just assign it as is to the card's property
					# (i.e. we do nothing at this point,
					# and it is assigned later in the code)
				else:
					modification = properties[property]
					new_value = modification
				# We do not check for alterants on card numer properties
				# which are set as strings (e.g. things like 'X')
				if typeof(card.get_property(property)) == TYPE_INT:
					alteration = _check_for_property_alterants(
							script,
							card.get_property(property),
							new_value,
							modification,
							property)
					if alteration is GDScriptFunctionState:
						alteration = yield(alteration, "completed")
			# We set the value according to whatever was in the script
			# which covers string and array values
			# but integers will need some processing for alterants.
			var value = properties[property]
			# Alteration should work on both property sets and mods
			# Since mods are specified with a string (e.g. "+3")
			# We need to convert the value + alteration into a string as well
			if alteration != null:
				value = modification + alteration
				# We cannot check for +/- using .is_valid_integer() because
				# the value might be something like '+per_counter'
				if typeof(properties[property]) == TYPE_STRING\
						and ('+' in properties[property] or '-' in properties[property]):
					# If the value is positive, we need to put the '+' in front
					if value >= 0:
						value = '+' + str(value)
					# If the value is negative, the '-' in front will be there
					else:
						# modify_property(), always expects a string for a value
						value = str(value)
			var ret_once = card.modify_property(
					property,
					value,
					costs_dry_run(),
					tags)
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
#	* [KEY_ASK_INTEGER_MIN](ScriptProperties#KEY_ASK_INTEGER_MIN)
#	* [KEY_ASK_INTEGER_MAX](ScriptProperties#KEY_ASK_INTEGER_MAX)
func ask_integer(script: ScriptTask) -> void:
	var integer_dialog = _ASK_INTEGER_SCENE.instance()
	# AskInteger tasks have to always provide a min and max value
	var minimum = script.get_property(SP.KEY_ASK_INTEGER_MIN)
	var maximum = script.get_property(SP.KEY_ASK_INTEGER_MAX)
	integer_dialog.prep(script.owner.canonical_name, minimum, maximum)
	# We have to wait until the player has finished selecting an option
	yield(integer_dialog,"popup_hide")
	stored_integer = integer_dialog.number
	# Garbage cleanup
	integer_dialog.queue_free()


# Adds a specified BoardPlacementGrid scene to the board at the specified position
# * Requires the following keys:
#	* [KEY_SCENE_PATH](ScriptProperties#KEY_SCENE_PATH): path to BoardPlacementGrid .tscn file
#	* One of the following:
#		* [KEY_BOARD_POSITION](ScriptProperties#KEY_BOARD_POSITION)
#		* [KEY_GRID_NAME](ScriptProperties#KEY_GRID_NAME)
# * Optionally uses the following keys:
#	* [KEY_OBJECT_COUNT](ScriptProperties#KEY_OBJECT_COUNT)
#	* [KEY_GRID_NAME](ScriptProperties#KEY_GRID_NAME)
func add_grid(script: ScriptTask) -> void:
	var count: int
	var grid_name : String = script.get_property(SP.KEY_GRID_NAME)
	var board_position: Vector2 = script.get_property(SP.KEY_BOARD_POSITION)
	var grid_scene: String = script.get_property(SP.KEY_SCENE_PATH)
	if str(script.get_property(SP.KEY_OBJECT_COUNT)) == SP.VALUE_RETRIEVE_INTEGER:
		count = stored_integer
		if script.get_property(SP.KEY_IS_INVERTED):
			count *= -1
		count += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	else:
		count = script.get_property(SP.KEY_OBJECT_COUNT)
	for iter in range(count):
		var grid: BoardPlacementGrid = load(grid_scene).instance()
		# A small delay to allow the instance to be added
		yield(script.owner.get_tree().create_timer(0.05), "timeout")
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
				iter * grid.card_size.y * grid.card_play_scale

# Task for modifying a a counter.
# If this task is specified, the variable [counters](Board#counters) **has** to be set
# inside the board script
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST).
# * Can be affected by [Alterants](ScriptProperties#KEY_ALTERANTS)
# * Requires the following keys:
#	* [KEY_COUNTER_NAME](ScriptProperties#KEY_COUNTER_NAME)
#	* [KEY_MODIFICATION](ScriptProperties#KEY_MODIFICATION)
# * Optionally uses the following keys:
#	* [KEY_SET_TO_MOD](ScriptProperties#KEY_SET_TO_MOD)
func mod_counter(script: ScriptTask) -> int:
	var counter_name: String = script.get_property(SP.KEY_COUNTER_NAME)
	var modification: int
	var alteration = 0
	# We inject the tags from the script into the tags sent by the signal
	var tags: Array = ["Scripted"] + script.get_property(SP.KEY_TAGS)
	if str(script.get_property(SP.KEY_MODIFICATION)) == SP.VALUE_RETRIEVE_INTEGER:
		# If the modification is requested, is only applies to stored integers
		# so we flip the stored_integer's value.
		modification = stored_integer
		if script.get_property(SP.KEY_IS_INVERTED):
			modification *= -1
		modification += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	elif SP.VALUE_PER in str(script.get_property(SP.KEY_MODIFICATION)):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_MODIFICATION),
				script.owner,
				script.get_property(script.get_property(SP.KEY_MODIFICATION)),
				null,
				script.subjects,
				script.prev_subjects)
		modification = per_msg.found_things
	else:
		modification = script.get_property(SP.KEY_MODIFICATION)
	var set_to_mod: bool = script.get_property(SP.KEY_SET_TO_MOD)
	if not set_to_mod:
		alteration = _check_for_alterants(script, modification)
		if alteration is GDScriptFunctionState:
			alteration = yield(alteration, "completed")
	if script.get_property(SP.KEY_STORE_INTEGER):
		var current_count = cfc.NMAP.board.counters.get_counter(
				counter_name, script.owner)
		if set_to_mod:
			stored_integer = modification + alteration - current_count
		elif current_count + modification + alteration < 0:
			stored_integer = -current_count
		else:
			stored_integer = modification + alteration
	var retcode: int = cfc.NMAP.board.counters.mod_counter(
			counter_name,
			modification + alteration,
			set_to_mod,
			costs_dry_run(),
			script.owner,
			tags)
	return(retcode)


# Task for executing scripts on subject cards.
# * Supports [KEY_IS_COST](ScriptProperties#KEY_IS_COST). If it is set, the cost check
#	will fail, if any of the target card's cost checks also fail.
# * Requires the following keys:
#	* [KEY_SUBJECT](ScriptProperties#KEY_SUBJECT)
# * Optionally uses the following keys:
#	* [KEY_REQUIRE_EXEC_STATE](ScriptProperties#KEY_REQUIRE_EXEC_STATE)
#	* [KEY_EXEC_TEMP_MOD_PROPERTIES](ScriptProperties#KEY_EXEC_TEMP_MOD_PROPERTIES)
#	* [KEY_EXEC_TEMP_MOD_COUNTERS](ScriptProperties#KEY_EXEC_TEMP_MOD_COUNTERS)
#	* [KEY_EXEC_TRIGGER](ScriptProperties#KEY_EXEC_TRIGGER)
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
					script.owner,
					script.get_property(SP.KEY_EXEC_TRIGGER),
					{}, costs_dry_run())
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


# Task for executing nested tasks
# This task will execute internal non-cost cripts accordin to its own
# nested cost instructions.
# Therefore if you set this task as a cost,
# it will modify the board, even if other costs of this script
# could not be paid.
# You can use [SP.KEY_ABORT_ON_COST_FAILURE](SP#KEY_ABORT_ON_COST_FAILURE)
# to control this behaviour better
func nested_script(script: ScriptTask) -> int:
	var retcode : int = CFConst.ReturnCode.CHANGED
	var nested_task_list: Array = script.get_property(SP.KEY_NESTED_TASKS)
	var sceng = cfc.scripting_engine.new(
			nested_task_list,
			script.owner,
			script.trigger_object,
			script.trigger_details)
	# In case the script involves targetting, we need to wait on further
	# execution until targetting has completed
	sceng.execute(CFInt.RunType.COST_CHECK)
	if not sceng.all_tasks_completed:
		yield(sceng,"tasks_completed")
	# If the dry-run of the ScriptingEngine returns that all
	# costs can be paid, then we proceed with the actual run
	if sceng.can_all_costs_be_paid:
		sceng.execute()
		if not sceng.all_tasks_completed:
			yield(sceng,"tasks_completed")
	# This will only trigger when costs could not be paid, and will
	# execute the "is_else" tasks
	elif not sceng.can_all_costs_be_paid:
		sceng.execute(CFInt.RunType.ELSE)
	# If the nested task had a cost which could not be paid
	# we return a failed result. This means that if the nested_script task
	# was also marked as a cost itself, then it will block execution of
	# further non-cost tasks.
	if not sceng.can_all_costs_be_paid:
		retcode = CFConst.ReturnCode.FAILED
	return(retcode)


# Does nothing. Useful for selecting subjects to pass to further filters etc.
# warning-ignore:unused_argument
func null_script(script: ScriptTask) -> int:
	return(CFConst.ReturnCode.CHANGED)


# Initiates a seek through the table to see if there's any cards
# which have scripts which modify the intensity of the current task.
func _check_for_alterants(script: ScriptTask, value: int, subject = null) -> int:
	var alteration = CFScriptUtils.get_altered_value(
		script.owner,
		script.script_name,
		script.script_definition,
		value,
		subject)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	return(alteration.value_alteration)


# Initiates a seek through the table to see if there's any cards
# which have scripts which modify the intensity of modify_properties tasks
# This is very much like _check_for_alterants, but it requires a customized
# dictionary to be sent, so we need more complex inputs as well
func _check_for_property_alterants(
		script: ScriptTask,
		old_value: int,
		new_value: int,
		value: int,
		property: String) -> int:
	var script_def = script.script_definition.duplicate()
	# When altering properties, we want to search for alterants
	# only for the specific property we're changing
	script_def[SP.TRIGGER_PROPERTY_NAME] = property
	script_def[SP.KEY_MODIFICATION] =\
			script_def[SP.KEY_MODIFY_PROPERTIES][property]
	script_def[SP.TRIGGER_PREV_COUNT] = old_value
	script_def[SP.TRIGGER_NEW_COUNT] = new_value
	var alteration = CFScriptUtils.get_altered_value(
		script.owner,
		script.script_name,
		script_def,
		value)
	if alteration is GDScriptFunctionState:
		alteration = yield(alteration, "completed")
	return(alteration.value_alteration)


func _retrieve_temp_modifiers(script: ScriptTask, type: String) -> Dictionary:
	var temp_modifiers: Dictionary
	if type == "properties":
		temp_modifiers = script.get_property(
				SP.KEY_TEMP_MOD_PROPERTIES).duplicate()
	else:
		temp_modifiers = script.get_property(
				SP.KEY_TEMP_MOD_COUNTERS).duplicate()
	for value in temp_modifiers:
		if str(temp_modifiers[value]) == SP.VALUE_RETRIEVE_INTEGER:
			temp_modifiers[value] = stored_integer
			if script.get_property(SP.KEY_IS_INVERTED):
				temp_modifiers[value] *= -1
			temp_modifiers[value] += script.get_property(SP.KEY_ADJUST_RETRIEVED_INTEGER)
	return(temp_modifiers)

# Extendable function to perform extra checks on the script
# according to game logic
func _pre_task_exec(_script: ScriptTask) -> void:
	pass
	
