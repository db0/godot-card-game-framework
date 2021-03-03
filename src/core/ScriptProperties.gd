# This class provides a library for constants which are used a key values
# in the Card Script Definition
#
# It also provides a few static functions for comparing filters
class_name ScriptProperties
extends Reference


#---------------------------------------------------------------------
# Script Definition Keys
#
# The below are all the possible dictionary keys that can be set in a
# task definition.
# Most of them are only relevant for a specific task type
#---------------------------------------------------------------------

# Value Type: String
# * [KEY_SUBJECT_V_TARGET](#KEY_SUBJECT_V_TARGET)
# * [KEY_SUBJECT_V_SELF](#KEY_SUBJECT_V_SELF)
# * [KEY_SUBJECT_V_BOARDSEEK](#KEY_SUBJECT_V_BOARDSEEK)
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
# * [KEY_SUBJECT_V_PREVIOUS](#KEY_SUBJECT_V_PREVIOUS)
#
# Determines which card, if any, this script will try to affect.
#
# If key does not exist, we set value to [],  thereogr assuming
# there's no card subjects needed for the task.
#
# If you need to adjust the amount of cards modified by the script
# also use [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT)
const KEY_SUBJECT := "subject"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# we initiate targetting from the owner card
const KEY_SUBJECT_V_TARGET := "target"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then the task affects the owner card only.
const KEY_SUBJECT_V_SELF := "self"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# during [KEY_ALTERANTS](#KEY_ALTERANTS) scripts using [KEY_PER](#KEY_PER)
# then the script will check against trigger card only.
#
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# during normal scripts tasks then the
# tasks that do not match the triggers will be skipped
# but the script will still pass its cost check
# This allows the same trigger, to have different tasks firing, depending
# on the trigger card.
const KEY_SUBJECT_V_TRIGGER := "trigger"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we search all cards on the table
# by node order, and return candidates equal to
# [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT) that match the filters.
#
# This allows us to make tasks which will affect more than 1 card at
# the same time (e.g. "All Soldiers")
const KEY_SUBJECT_V_BOARDSEEK := "boardseek"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we search all cards on the specified
# pile by node order, and pick the first candidate that matches the filter
#
# When this value is used [KEY_SRC_CONTAINER](KEY_SRC_CONTAINER)
# has to also be used.
const KEY_SUBJECT_V_TUTOR := "tutor"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we pick the card on the specified
# source pile by its index among other cards.
#
# When this value is used [KEY_SRC_CONTAINER](KEY_SRC_CONTAINER)
# has to also be used.
const KEY_SUBJECT_V_INDEX := "index"
# If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we use the subject specified in the previous task
const KEY_SUBJECT_V_PREVIOUS := "previous"
# Value Type: Dynamic (Default = 1)
# * int
# * [KEY_SUBJECT_COUNT_V_ALL](#KEY_SUBJECT_COUNT_V_ALL)
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
#
# Used when we're seeking a card
# to limit the amount to retrieve to this amount.
#
# Works with the following tasks and [KEY_SUBJECT](#KEY_SUBJECT) values:
# * [KEY_SUBJECT_V_BOARDSEEK](#KEY_SUBJECT_V_BOARDSEEK)
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
# * [KEY_SUBJECT_V_INDEX](#KEY_SUBJECT_V_INDEX)
const KEY_SUBJECT_COUNT := "subject_count"
# When specified as the value of [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT),
# will retrieve as many cards as match the criteria.
#
# Useful with the following values:
# * [KEY_SUBJECT_V_BOARDSEEK](#KEY_SUBJECT_V_BOARDSEEK)
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
const KEY_SUBJECT_COUNT_V_ALL := "all"
# Value Type: bool (Default = false).
#
# This key is used to mark a task as being a cost requirement before the
# rest of the defined tasks can execute.
#
# If any tasks marked as costs will not be able to fulfil, then the whole
# script is not executed.
#
# Currently the following tasks support being set as costs:
# * [rotate_card](ScriptingEngine#rotate_card)
# * [flip_card](ScriptingEngine#flip_card)
# * [mod_tokens](ScriptingEngine#mod_tokens)
# * [mod_counter](ScriptingEngine#mod_tokens)
# * [move_card_to_container](ScriptingEngine#move_card_to_container)
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
const KEY_IS_COST := "is_cost"
# Value Type: bool (Default = false).
#
# This key is used to mark a task to be executed only if the card costs
# cannot be paid. As such, they will never fire,unless the card also has
# an "is_cost" task.
const KEY_IS_ELSE := "is_else"
# Value Type: String (Default = false).
# * "self": Triggering card has to be the owner of the script
# * "another": Triggering card has to not be the owner of the script
# * "any" (default): Will execute regardless of the triggering card.
#
# Used when a script is triggered by a signal.
# Limits the execution depending on the triggering card.

const KEY_TRIGGER := "trigger"
# Value Type: int.
#
# Used when a script is using the [rotate_card](ScriptingEngine#rotate_card) task.
#
# These are the degress in multiples of 90, that the subjects will be rotated.
const KEY_DEGREES := "degrees"
# Value Type: bool.
# * true: The card will be set face-up
# * false: The card will be set face-down
#
# Used when a script is using the [flip_card](ScriptingEngine#flip_card) task.
const KEY_SET_FACEUP := "set_faceup"
# Value Type: bool.
#
# Used when a script is using the modify_properties task.
# The value is supposed to be a dictionary of `"property name": value` entries
const KEY_MODIFY_PROPERTIES := "set_properties"
# Value Type: [Pile].
#
# Used when a script is using one of the following tasks
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
# * [move_card_to_container](ScriptingEngine#move_card_to_container)
#
# When the following [KEY_SUBJECT](#KEY_SUBJECT) values are also used:
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
# * [KEY_SUBJECT_V_INDEX](#KEY_SUBJECT_V_INDEX)
#
# Specifies the source container to pick the card from
const KEY_SRC_CONTAINER := "src_container"
# Value Type: [Pile].
#
# Used when a script is using one of the following tasks
# * [move_card_to_container](ScriptingEngine#move_card_to_container)
# * [shuffle_container](ScriptingEngine#shuffle_container)
#
# Specifies the destination container to manipulate
const KEY_DEST_CONTAINER := "dest_container"
# Value Options (Default = 0):
# * int
# * [KEY_SUBJECT_INDEX_V_TOP](#KEY_SUBJECT_INDEX_V_TOP)
# * [KEY_SUBJECT_INDEX_V_BOTTOM](#KEY_SUBJECT_INDEX_V_BOTTOM)
# * [KEY_SUBJECT_INDEX_V_RANDOM](#KEY_SUBJECT_INDEX_V_RANDOM)
#
# Used when we're seeking a card inside a [CardContainer]
# in one of the following tasks
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
# * [move_card_to_container](ScriptingEngine#move_card_to_container)
#
# Default is to seek card at index 0
const KEY_SUBJECT_INDEX := "subject_index"
# Special entry to be used with [KEY_SUBJECT_INDEX](#KEY_SUBJECT_INDEX)
# instead of an integer.
#
# If specified, explicitly looks for the top "card" of a pile
const KEY_SUBJECT_INDEX_V_TOP := "top"
# Special entry to be used with [KEY_SUBJECT_INDEX](#KEY_SUBJECT_INDEX)
# instead of an integer.
#
# If specified, explicitly looks for the "bottom" card of a pile
const KEY_SUBJECT_INDEX_V_BOTTOM := "bottom"
# Special entry to be used with [KEY_SUBJECT_INDEX](#KEY_SUBJECT_INDEX)
# instead of an integer.
#
# If specified, picks a random index in the container
const KEY_SUBJECT_INDEX_V_RANDOM := "random"
# Value Type: Dynamic (Default = [KEY_SUBJECT_INDEX_V_TOP](#KEY_SUBJECT_INDEX_V_TOP))
# * int
# * [KEY_SUBJECT_INDEX_V_TOP](#KEY_SUBJECT_INDEX_V_TOP)
# * [KEY_SUBJECT_INDEX_V_BOTTOM](#KEY_SUBJECT_INDEX_V_BOTTOM)
#
# Used when placing a card inside a [CardContainer]
# using the [move_card_to_container](ScriptingEngine#move_card_to_container) task
# to specify which index inside the CardContainer to place the card
const KEY_DEST_INDEX := "dest_index"
# Value Type: Vector2.
#
# Used in the following tasks
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
# * [spawn_card](ScriptingEngine#spawn_card)
# * [add_grid](ScriptingEngine#add_grid)
#
# It specfies the position of the board to place the subject or object of the task.
# If used in combination with [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT)
# the task will attempt to place all subjects/objects in a way that they
# do not overlap.
const KEY_BOARD_POSITION := "board_position"
# Value Type: String.
#
# Used in the following tasks
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
# * [spawn_card](ScriptingEngine#spawn_card)
# * [add_grid](ScriptingEngine#add_grid)
#
# For `move_card_to_board` and `spawn_card`, if specified,
# it will take priority over [KEY_BOARD_POSITION](#KEY_BOARD_POSITION)
# The card will be placed to the specified grid on the board
#
# For `add_grid`, if not specified, the grid will be keep the names
# defined in the scene. If specified, the node name and label
# will use the provided value
#
# This task will not check that the grid exists or that the card's
# mandatory grid name matches the grid name. The game has to be developed
# to not cause this situation.
const KEY_GRID_NAME := "grid_name"
# Value Type: String.
#
# Used with the [mod_counter](ScriptingEngine#mod_counter) task to specify
# Which counter to modify with this task
const KEY_COUNTER_NAME := "counter_name"
# Value Type: bool (Default = false).
#
# Used when a script is using one of the following tasks:
# * [mod_tokens](ScriptingEngine#mod_tokens)
#
# It specifies if we're modifying the existing amount
# or setting it to the exact one
const KEY_SET_TO_MOD := "set_to_mod"
# Value Type: String
#
# Used when a script is using the [mod_tokens](ScriptingEngine#mod_tokens) task.
#
# It specifies the name of the token we're modifying
const KEY_TOKEN_NAME := "token_name"
# Value Type: Dynamic
# * int
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
# * [VALUE_PER](#VALUE_PER)
#
# Used when a script is using one of the following tasks:
# * [mod_tokens](ScriptingEngine#mod_tokens)
# * [mod_counter](ScriptingEngine#mod_counter)
#
# It specifies the amount we're setting/modifying
# or setting it to the exact one
const KEY_MODIFICATION := "modification"
# Value Type: bool (Default = false).
#
# Used when a script is using one of the following tasks:
# * [mod_tokens](ScriptingEngine#mod_tokens)
# * [mod_counters](ScriptingEngine#mod_tokens)
#
# Stores the modification difference into an integer to
# be used in later tasks.
const KEY_STORE_INTEGER := "store_integer"
# Value Type: Dynamic (Default = 1).
# * int.
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
# * [VALUE_PER](#VALUE_PER)

# Used in conjunction with the following tasks
# * [spawn_card](ScriptingEngine#spawn_card)
# * [add_grid](ScriptingEngine#add_grid)
#
# specified how many of the "thing" done by the task, to perform.
const KEY_OBJECT_COUNT := "object_count"
# Value Type: String
#
# Used in conjunction with the following tasks
# * [add_grid](ScriptingEngine#add_grid)
#
# This is the path to the scene we will add to the game.
const KEY_SCENE_PATH := "scene_path"
# Value Type: String
#
# Used in conjunction with the following tasks
# * [spawn_card](ScriptingEngine#spawn_card)
#
# This is name of the card that will be added to the game.
const KEY_CARD_NAME := "card_name"
# Value Type: int
#
# Used by the [ask_integer](ScriptingEngine#ask_integer) task.
# Specifies the minimum value the number needs to have
const KEY_ASK_INTEGER_MIN := "ask_int_min"
# Value Type: int
#
# Used by the [ask_integer](ScriptingEngine#ask_integer) task.
# Specifies the maximum value the number needs to have
const KEY_ASK_INTEGER_MAX := "ask_int_max"
# Value Type: Array of Strings
# All card manipulation Signals will send a list of tags
# marking the type of effect that triggered them. 
#
# By Default it's the tags sent is just ["Manual"] 
# for manipulation via the core API methods.
# However when the manipulation is done via ScriptingEngine, the tags
# can be modified by the script defintion. The ScrptingEngine will always
# mark them as "Scripted" instead of "Manual" at the least.
#
# With this key, you can specify a number of keywords 
# you can assign to your script, which details what function it is serving.
# These can be hooked on by the [AlterantEngine] and the [ScriptingEngine]
# to figure out if this script effects should be altered or triggered. 
#
# Tags specified with ScriptTasks will be injected along with list sent
# by the ScriptingEngine. So for example `"tags": ["PlayCost"]` 
# will be sent as ["Scripted", "PlayCost"] by the ScriptingEngine.
#
# A signal or script has to have all the tags a 
# [FILTER_TAGS](#FILTER_TAGS) task is looking for, in order to be considered.
const KEY_TAGS := "tags"
# Value Type: Dictionary
#
# Used in place of a trigger name (e.g. 'manual'). This key allows the card to be marked as
# an "Alterant". I.e. a card which will modify the values of other scripts or
# effects.
#
# For example cards which reduce or increase costs,
# or cards which intensify the effect of other cards would be alterants.
#
# The dictionary inside follows a similar format to a typical script,
# with the [state_exec](Card#get_state_exec) of the card being the next key,
# specifying when the alterant is active, and inside that,
# an array of mulitple alterants to check against.
#
# A sample alterant definition might look like this
#```
#{"alterants": {
#	"board": [
#		{"filter_task": "mod_counter",
#		"trigger": "another",
#		"filter_tags": ["PlayCost"],
#		"filter_counter_name": "research",
#		"filter_state_trigger": [{
#			"filter_properties": {"Type": "Science"}
#		}],
#		"alteration": -1}
#	]
#}}
#```
# The above would roughly translate to *"Whenever you are playing a Science card
# reduce it's research cost by 1"*
#
# The main difference from other scripts being that
# triggers are checked inside each individual alterant task,
# rather than on the whole script. This allows the same card
# to modify different sort of cards and triggers, in different ways.
#
# Currently the following tasks support being altered during runtime via alterants
# * [mod_tokens](ScriptingEngine#mod_tokens)
# * [mod_counter](ScriptingEngine#mod_counter)
# * [spawn_card](ScriptingEngine#spawn_card)
#
# When this is used [KEY_ALTERATION](KEY_ALTERATION) also needs to be defined.
const KEY_ALTERANTS := "alterants"
# Value Type: int
#
# Used by the [AlterantEngine] to determine by how much it should modify
# the currently performed task.
#
# It can accept a [VALUE_PER](#VALUE_PER) value which allows one to script an
# effect like "Increase the cost by the number of Soldiers on the table"
const KEY_ALTERATION := "alteration"
# This is a versatile value that can be inserted into any various keys
# when a task needs to calculate the amount of subjects to look for
# or the number of things to do, based on the state of the board at that point
# in time.
# The value has to be appended with the type of seek to do to determine
# the amount. The full value has to match one of the following keys:
# * [KEY_PER_TOKEN](#KEY_PER_TOKEN)
# * [KEY_PER_PROPERTY](#KEY_PER_PROPERTY)
# * [KEY_PER_TUTOR](#KEY_PER_TUTOR)
# * [KEY_PER_BOARDSEEK](#KEY_PER_BOARDSEEK)
# * [KEY_PER_COUNTER](#KEY_PER_COUNTER)
#
# When this value is set, the relevant key **must** also exist in the
# Script definition. They key shall contain a dictionary which will
# Specify the subjects as well as the things to count.
#
# Inside the per_ key, you again have to specify [KEY_SUBJECT](#KEY_SUBJECT)
# lookup which is relevant for the per search.
#
# This allows us to calculate the effects of card scripts during runtime.
# For a complex example:
#```
#{"manual":
#	{"hand": [
#		{"name": "move_card_to_container",
#		"subject": "index",
#		"subject_count": "per_boardseek",
#		"src_container": deck,
#		"dest_container": hand,
#		"subject_index": "top",
#		"per_boardseek": {
#			"subject": "boardseek",
#			"subject_count": "all",
#			"filter_state_seek": [
#				{"filter_properties": {
#					"Power": 0}
#				}
#			]
#		}}
#	]}
#}
#```
# The above example can be tranlated to:
# *"Draw 1 card for each card with 0 power on the board"*
const VALUE_PER := "per_"
# Value Type: String
#
# This key is typically needed in combination with 
# [KEY_PER_PROPERTY](#KEY_PER_PROPERTY)
# to specify which property to base the per upon.
# When used this way, the property **has** to be a number.
#
# Also used by Alterant filters, to specify which property to compare against
# When adjusting a property on-the-fly
const KEY_PROPERTY_NAME := "property_name"
# Value Type: String (Default = "manual").
#
# This is used with the [execute_scripts](ScriptingEngine#execute_scripts)
# task to determine which execution trigger to run.
const KEY_EXEC_TRIGGER := "exec_trigger"
# Value Type: String
#
# This is used with the [execute_scripts](ScriptingEngine#execute_scripts)
# task to limit execution, only to cards in the right state ("board","hand" or "pile)
#
# If this is not defined, it will execute the specified exec_trigger of the
# state the card is currently in, if any exists for it.
const KEY_REQUIRE_EXEC_STATE := "require_exec_state"
# Value Type: Dictionary
#
# This key is used in [execute_scripts](ScriptingEngine#execute_scripts)
# to temporary alter the value of a counter by a specified amount.
#
# The value has to be a Dictionary where each key is an counter's name
# and the value is the modification to use on that counter.
const KEY_TEMP_MOD_COUNTERS := "temp_mod_counters"
# Value Type: Dictionary
#
# This key is used in [execute_scripts](ScriptingEngine#execute_scripts)
# to temporary alter the numerical properties the target card think is has,
# by a specified amount.
#
# The value has to be a Dictionary where each key is an number property's name
# As defined in [PROPERTIES_NUMBERS](CardConfig#PROPERTIES_NUMBERS)
# and the value is the modification to use on that number
const KEY_TEMP_MOD_PROPERTIES := "temp_mod_properties"
# Value Type: Bool (Default = false)
#
# Used in the per dictionary to specify that the amount of things counted
# should be returned negative.
# This allows to have costs based on the boardstate
const KEY_IS_INVERTED := "is_inverted"
# Value Type: Dictionary
#
# A [VALUE_PER](#VALUE_PER) key for perfoming an effect equal to a number of tokens on the subject(s)
#
# Other than the subject defintions the [KEY_TOKEN_NAME](#KEY_TOKEN_NAME)
# has to also be provided
const KEY_PER_TOKEN := "per_token"
# Value Type: Dictionary
#
# A [VALUE_PER](#VALUE_PER) key for perfoming an effect equal to a accumulated property on the subject(s)
#
# Other than the subject defintions the [KEY_PROPERTY_NAME](#KEY_PROPERTY_NAME)
# has to also be provided. Obviously, the property specified has to be a number.
const KEY_PER_PROPERTY := "per_property"
# Value Type: Dictionary
#
# A [VALUE_PER](#VALUE_PER) key for perfoming an effect equal to a number
# of cards in pile matching a filter.
#
# Typically the [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT)
# inside this dictionary would be set to
# [KEY_SUBJECT_COUNT_V_ALL](#KEY_SUBJECT_COUNT_V_ALL),
# but a [FILTER_STATE](#FILTER_STATE) should also be typically specified
const KEY_PER_TUTOR := "per_tutor"
# Value Type: Dictionary
#
# A [VALUE_PER](#VALUE_PER) key for perfoming an effect equal the number of
# cards on the board matching a filter.
#
# Typically the [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT)
# inside this dictionary would be set to
# [KEY_SUBJECT_COUNT_V_ALL](#KEY_SUBJECT_COUNT_V_ALL),
# but a [FILTER_STATE](#FILTER_STATE) should also be typically specified
const KEY_PER_BOARDSEEK := "per_boardseek"
# Value Type: Dictionary
#
# A [VALUE_PER](#VALUE_PER) key for perfoming an effect
# equal to the value of a counter.
const KEY_PER_COUNTER := "per_counter"
# Value Type: String. One of the below:
# * "eq" (Defaut): Equal
# * "ne": Not equal
# * "gt": Greater than
# * "lt": Less than
# * "le": Less than or Equal
# * "ge": Geater than or equal
#
# Key is used typically to do comparisons during filters involving
# numerical numbers. However the "eq" and "ne" can be used to compare strings
# as well.
#
# I.e. it allows to write the script for something like:
# *"Destroy all Monsters with cost equal or higher than 3"*
const KEY_COMPARISON := "comparison"
# This is a versatile value that can be inserted into any various keys
# when a task needs to use a previously inputed integer provided
# with a [ask_integer](ScriptingEngine#ask_integer) task
# or a [KEY_STORE_INTEGER](#KEY_STORE_INTEGER).
#
# When detected ,the task will retrieve the stored number and use it as specified
#
# The following keys support this value
# * [KEY_MODIFICATION](#KEY_MODIFICATION)
# * [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT) (only for specific tasks, see documentation)
# * [KEY_OBJECT_COUNT](#KEY_OBJECT_COUNT) (only for specific tasks, see documentation)
# * [KEY_TEMP_MOD_PROPERTIES](#KEY_TEMP_MOD_PROPERTIES) (In the value fields)
# * [KEY_TEMP_MOD_COUNTERS](#KEY_TEMP_MOD_COUNTERS) (In the value fields)
const VALUE_RETRIEVE_INTEGER := "retrieve_integer"
# Value Type: bool (Default = false)
#
# Specifies whether this script or task can be skipped by the owner.
#
# If it is making a sigle task optional, you need to add "task" at the end
# and place it inside a single task definition
# Example:
# ```
#"manual": {
#	"board": [
#		{"name": "rotate_card",
#		"is_optional_task": true,
#		"subject": "self",
#		"degrees": 90},
#	]}
# ```
# If you need to make a whole [state_exec](Card#get_state_exec) optional,
# then you need to place it on the same level as the state_exec
# and append the state_exec name
# Example:
# ```
#"card_flipped": {
#	"is_optional_board": true,
#	"board": [
#		{"name": "rotate_card",
#		"is_cost": true,
#		"subject": "self",
#		"degrees": 90}
#	]}
# ```
# When set to true, a confirmation window will appear to the player
# when this script/task is about to execute.
#
# At the task level, it will ask the player before activating that task only
# If that task [is a cost](#KEY_IS_COST), it will also prevent subsequent tasks
# from firing
#
# At the script level, the whole script if cancelled.
const KEY_IS_OPTIONAL := "is_optional_"
#---------------------------------------------------------------------
# Filter Definition Keys
#
# The below are all the possible dictionary keys that can be set in a
# filter definition.
# Most of them are only relevant for a specific task type
#---------------------------------------------------------------------

# Value Type: Array
#
# Filter used for checking against the Card state
#
# The name of this key is left open ended, as the check can be run either
# against the trigger card, or the subjects card.
#
# One of the following strings **has** to be appended at the end of this string:
# * "trigger": Will only filter cards triggering this effect via signals
#	or cards triggering an alterant effect.
# * "subject": Will only filter cards that are looked up as targets for the effect.
# * "seek": Will only filter cards that are automatically sought on the board.
# * "tutor": Will only filter cards that are automaticaly sought in a pile.
#
# see [check_validity()](#check_validity-static)
#
# The content of this value has to be an array of dictionaries
# The different elements in the array act as an "OR" check. If **any** of the
# dictionary filters matches, then the card will be considered a valid target.
#
# Each filter  dictionary has to contain at least one of the various FILTER_ Keys
# All the FILTER_ keys act as an "AND" check. The Dictionary filter will only
# match, if **all** the filters requested match the card's state.
#
# This allows a very high level of flexibility in filtering exactly the cards
# required.
#
# Here's a particularly complex script example that can be achieved:
#```
#"manual": {
#	"hand": [
#		{"name": "rotate_card",
#		"subject": "boardseek",
#		"subject_count": "all",
#		"filter_state_seek": [
#			{"filter_tokens": [
#				{"filter_token_name": "void",
#				"filter_token_count": 1,
#				"comparison": "gt"},
#				{"filter_token_name": "blood"}
#			],
#			"filter_properties": {"Type": "Barbarian"}},
#			{"filter_properties": {"Type": "Soldier"}}
#		],
#		"degrees": 90}
#	]
#}
#```
# This example would roughly translate to the following ability:
# *"Rotate to 90 degrees all barbarians with more than 1 void tokens and
# at least 1 blood token, as well as all soldiers."*
const FILTER_STATE := "filter_state_"
# Value Type: Dictionary
#
# Filter used for checking against the Card properties
#
# Each value is a dictionary where the  key is a card property, and the value
# is the desired property value to match on the filtered card.
#
# If the card property is numerical, 
# then the value can be a string. 
# In that case it is assumed that the string is a counter name 
# against which to compare the property value
const FILTER_PROPERTIES := "filter_properties"
#Value Type: Node.
#
# Filter used for checking against the parent node of a subject.
# Only used within the [FILTER_STATE](#FILTER_STATE) Dictionary
#
# The value should be either the board, or a CardContainer.
const FILTER_PARENT := "filter_parent"

# Value Type: int.
#
# Filter used in for checking against [TRIGGER_DEGREES](#KEY_MODIFICATION)
const FILTER_DEGREES := "filter_degrees"
# Value Type: bool.
#
# Filter for checking against [TRIGGER_FACEUP](#TRIGGER_FACEUP)
const FILTER_FACEUP := "filter_faceup"
# Value Type: Dynamic.
# * [Board]
# * [CardContainer]
#
# Filter for checking against [TRIGGER_SOURCE](#TRIGGER_SOURCE)
const FILTER_SOURCE := "filter_source"
# Value Type: Dynamic.
# * [Board]
# * [CardContainer]
#
# Filter for checking against [TRIGGER_DESTINATION](#TRIGGER_DESTINATION)
const FILTER_DESTINATION := "filter_destination"
# Value Type: int.
#
# Filter used for checking against [TRIGGER_NEW_COUNT](#TRIGGER_NEW_COUNT)
# and in [check_state](#check_state)
const FILTER_COUNT := "filter_count"
# Value Type: String
# * [TRIGGER_V_COUNT_INCREASED](#TRIGGER_V_COUNT_INCREASED)
# * [TRIGGER_V_COUNT_DECREASED](#TRIGGER_V_COUNT_DECREASED)
#
# Filter used to check if the modification is positive or negative
const FILTER_COUNT_DIFFERENCE := "filter_count_difference"
# Value Type: Dictionary
#
# Filter used for checking in [check_state](#check_state)
# It contains a list of dictionaries, each detailing a token state that
# is wished on this subject. If any of them fails to match, then the whole
# filter fails to match.
#
# This allows us to check for multiple tokens at once. For example:
# "If target has a blood and a void token..."
#
# The below sample script, will rotate all cards which have
# any number of void tokens and exactly 1 bio token, 90 degrees
#```
#"manual": {
#	"hand": [
#		{"name": "rotate_card",
#		"subject": "boardseek",
#		"subject_count": "all",
#		"filter_state_seek": {
#			"filter_tokens": [
#				{"filter_token_name": "void"},
#				{"filter_token_name": "bio",
#				"filter_token_count": 1},
#			]
#		},
#		"degrees": 90}
#	]
#}
#```
const FILTER_TOKENS := "filter_tokens"
# Value Type: Dictionary.
#
# Filter key used for checking against card_properties_modified details.
#
# Checking for modified properties is a bit trickier than other filters
# A signal emited from modified properties, will include as values the
# property name changed, and its new and old values.
#
# The filter specified in the card script definition, will have
# as the requested property filter, a dictionary inside the card_scripts
# with the key [FILTER_MODIFIED_PROPERTIES](#FILTER_MODIFIED_PROPERTIES).
#
# Inside that dictionary will be another dictionary with one key per
# property. That key inside will (optionally) have yet another dictionary
# within, with specific values to filter. A sample filter script for triggering
# only if a specific property was modified would look like this:
# ```
#{"card_properties_modified": {
#	"hand": [{
#		"name": "flip_card",
#		"subject": "self",
#		"set_faceup": false
#	}],
#	"filter_modified_properties":
#		{
#			"Type": {}
#		},
#	"trigger": "another"}
#}
# ```
# The above example will trigger only if the "Type" property of another card
# is modified. But it does not care to what value the Type property changed.
#
# A more advanced trigger might look like this:
# ```
#{"card_properties_modified": {
#	"hand": [{
#		"name": "flip_card",
#		"subject": "self",
#		"set_faceup": false
#		}],
#	"filter_modified_properties": {
#		"Type": {
#			"new_value": "Orange",
#			"previous_value": "Green"
#		}
#	},
#	"trigger": "another"}
#}
# ```
# The above example will only trigger on the "Type" property changing on
# another card, and only if it changed from "Green" to "Orange"
const FILTER_MODIFIED_PROPERTIES := "filter_modified_properties"
# Value Type: String.
#
# Filter used for checking against [TRIGGER_NEW_PROPERTY_VALUE](#TRIGGER_NEW_PROPERTY_VALUE)
const FILTER_MODIFIED_PROPERTY_NEW_VALUE := "new_value"
# Value Type: String.
#
# Filter used for checking against [TRIGGER_PREV_PROPERTY_VALUE](#TRIGGER_PREV_PROPERTY_VALUE)
const FILTER_MODIFIED_PROPERTY_PREV_VALUE := "previous_value"
# Value Type: String or Array of Strings
#
# A number of keywords to try and match against [KEY_TAGS](#KEY_TAGS)
# passed by the script or signal definition.
const FILTER_TAGS := "filter_tags"
# Value Type: String
#
# Filter used for checking against [TRIGGER_TASK_NAME](#TRIGGER_TASK_NAME)
const FILTER_TASK = "filter_task"
# Value Type: String
#
# Filter used for checking against [KEY_CARD_NAME](#KEY_CARD_NAME)
const FILTER_CARD_NAME = "filter_card_name"
# Value Type: Dictionary
#
# Requires similar input as [KEY_PER_BOARDSEEK](#KEY_PER_BOARDSEEK)
# But also needs [FILTER_CARD_COUNT](#FILTER_CARD_COUNT) specified
const FILTER_PER_TUTOR = "filter_per_tutor_count"
# Value Type: Dictionary
#
# Requires similar input as [KEY_PER_BOARDSEEK](#KEY_PER_BOARDSEEK)
# But also needs [FILTER_CARD_COUNT](#FILTER_CARD_COUNT) specified
const FILTER_PER_BOARDSEEK = "filter_per_boardseek_count"
# Value Type: int.
#
# Filter used for checking against the amount of cards found with
# [FILTER_PER_TUTOR](#FILTER_PER_TUTOR) and
# [FILTER_PER_BOARDSEEK](#FILTER_PER_BOARDSEEK) and needs to be placed within
# those dictionaries
const FILTER_CARD_COUNT := "filter_card_count"

#---------------------------------------------------------------------
# Trigger Properties
#
# The below are all the possible dictionary keys send in the dictionary
# passed by a card trigger signal (See Card signals) or by a script looking
# for alterant cards
#
# Most of them are only relevant for a specific task type
#---------------------------------------------------------------------

# Value Type: int.
#
# Filter value sent by the Card trigger `card_rotated` [signal](Card#signals).
#
# These are the degress in multiples of 90, that the subjects was rotated.
const TRIGGER_DEGREES := "degrees"
# Value Type: bool.
#
# Filter value sent by the Card trigger `card_flipped` [signal](Card#signals).
#
# This is the facing of trigger.
# * true: Trigger turned face-up
# * false: Trigger turned face-down
const TRIGGER_FACEUP := "is_faceup"
# Value Type: String.
#
# Filter value sent by the Card trigger `card_properties_modified` [signal](Card#signals).
#
# This is the property name
const TRIGGER_MODIFIED_PROPERTY_NAME := "property_name"
# Value Type: String.
#
# Filter value sent by the Card trigger `card_properties_modified` [signal](Card#signals).
#
# This is the current value of the property.
const TRIGGER_NEW_PROPERTY_VALUE := "new_property_value"
# Value Type: String.
#
# Filter value sent by the Card trigger `card_properties_modified` [signal](Card#signals).
#
# This is the value the property had before it was modified
const TRIGGER_PREV_PROPERTY_VALUE := "previous_property_value"
# Value Type: Dynamic.
# * [Board]
# * [CardContainer]
#
# Filter value sent by one of the trigger Card's following [signals](Card#signals):
# * card_moved_to_board
# * card_moved_to_pile
# * card_moved_to_hand
# The value will be the node name the Card left
const TRIGGER_SOURCE := "source"
# Value Type: Dynamic.
# * [Board]
# * [CardContainer]
#
# Filter value sent by one of the trigger Card's following [signals](Card#signals):
# * card_moved_to_board
# * card_moved_to_pile
# * card_moved_to_hand
# The value will be the node name the Card moved to
const TRIGGER_DESTINATION := "destination"
# Value Type: int.
#
# Filter value sent by the Card trigger `card_token_modified` [signal](Card#signals).
# and by the Counter trigger `counter_modified` [signal](Counters#signals)
#
# This is the current value of the token or counter.
#
# If token was removed value will be 0
const TRIGGER_NEW_COUNT := "new_count"
# Value Type: int.
#
# Filter value sent by the Card trigger `card_token_modified` [signal](Card#signals).
# and by the Counter trigger `counter_modified` [signal](Counters#signals)
#
# This is the value the token/counter had before it was modified.
#
# If token didn't exist, value will be 0
const TRIGGER_PREV_COUNT := "previous_count"
# Value Type: String.
#
# Filter value sent by the Card trigger `card_token_modified` [signal](Card#signals).
# as well as via the mod_tokens and get_token alterant scripts
#
# This is the value of the token name modified
const TRIGGER_TOKEN_NAME = "token_name"
# Value Type: String.
#
# Filter value sent by the Card trigger `card_token_modified` [signal](Card#signals).
# as well as via the mod_property and get_property alterant scripts
#
# This is the value of the token name modified
const TRIGGER_PROPERTY_NAME = "property_name"
# Value Type: String.
#
# Filter value sent by the Counters trigger `counter_modified` [signal](Counters#signals).
# as well as via the mod_counters and get_counter alterant scripts
#
# This is the value of the token name modified
const TRIGGER_COUNTER_NAME = "counter_name"
# Value Type: Card.
#
# Filter value sent by the following [signals](Card#signals).
# * card_attached
# * card_unattached
# It contains the host object onto which this card attached
# or from which it unattached
const TRIGGER_HOST = "host"
# Sent to the [AlterantEngine] by a task which allows alterations,
# which allows a alterant cards to filter on whether to modify this value.
# See [FILTER_TASK](#FILTER_TASK).
const TRIGGER_TASK_NAME = "task_name"

#---------------------------------------------------------------------
# Trigger Values
#
# Some filter check signals against specific constants. They are defined below
#---------------------------------------------------------------------

# Value is sent by trigger when new token count is higher than old token count.
# Compared against [FILTER_COUNT_DIFFERENCE](#FILTER_COUNT_DIFFERENCE)
const TRIGGER_V_COUNT_INCREASED := "increased"
# Value is sent by trigger when new token count is lower than old token count.
# Compared against [FILTER_COUNT_DIFFERENCE](#FILTER_COUNT_DIFFERENCE)
const TRIGGER_V_COUNT_DECREASED := "decreased"


# Returns the default value any script definition key should have
static func get_default(property: String):
	var default
	# for property details, see const definitionts
	match property:
		KEY_IS_COST,\
				KEY_IS_ELSE,\
				KEY_IS_INVERTED,\
				KEY_SET_TO_MOD,\
				KEY_IS_OPTIONAL,\
				KEY_STORE_INTEGER:
			default = false
		KEY_TRIGGER:
			default = "any"
		KEY_SUBJECT_INDEX:
			default = 0
		KEY_DEST_INDEX:
			default = -1
		KEY_BOARD_POSITION:
			default = Vector2(-1,-1)
		KEY_MODIFY_PROPERTIES,\
				KEY_TEMP_MOD_PROPERTIES,\
				KEY_TEMP_MOD_COUNTERS:
			default = {}
		KEY_SUBJECT_COUNT,\
				KEY_OBJECT_COUNT,\
				KEY_MODIFICATION:
			default = 1
		KEY_GRID_NAME:
			default = ""
		KEY_COMPARISON:
			default = "eq"
		KEY_TAGS:
			default = []
		KEY_EXEC_TRIGGER:
			default = "manual"
		_:
			default = null
	return(default)


# Ensures that all filters requested by the script are respected
#
# Will return `false` if any filter does not match the filter request.
# Otherise returns `true`
static func filter_trigger(
		card_scripts,
		trigger_card,
		owner_card,
		trigger_details) -> bool:
	# Checking card properties is its own function as it might be
	# called from other places as well
	var is_valid := check_validity(trigger_card, card_scripts, "trigger")

	# Here we check that the trigger matches the _request_ for trigger
	# A trigger which requires "another" card, should not trigger
	# when itself causes the effect.
	# For example, a card which rotates itself whenever another card
	# is rotated, should not automatically rotate when itself rotates.
	if is_valid\
			and card_scripts.get("trigger") == "self"\
			and trigger_card != owner_card:
		is_valid = false
	if is_valid\
			and card_scripts.get("trigger") == "another"\
			and trigger_card == owner_card:
		is_valid = false

	# Script tags filter checks
	var filter_tags = card_scripts.get(FILTER_TAGS)
	if is_valid and filter_tags:
		# We set the variable manually here because `.get(key,[])` returns null
		var script_tags = trigger_details.get(KEY_TAGS)
		if not script_tags:
			script_tags = []
		# FILTER_TAGS can handle one tag as a string
		# or multiple tags as an array.
		if typeof(filter_tags) == TYPE_ARRAY:
			for tag in filter_tags:
				if not tag in script_tags:
					is_valid = false
		else:
			if not filter_tags in script_tags:
				is_valid = false

	# Card task name filter checks
	if is_valid and card_scripts.get(FILTER_TASK) \
			and card_scripts.get(FILTER_TASK) != \
			trigger_details.get(TRIGGER_TASK_NAME):
		is_valid = false

	# Card Rotation filter checks
	if is_valid and card_scripts.get(FILTER_PARENT) \
			and check_parent_filter(trigger_card,card_scripts.get(FILTER_PARENT)):
		is_valid = false

	# Card Rotation filter checks
	if is_valid and card_scripts.get(FILTER_DEGREES) != null \
			and card_scripts.get(FILTER_DEGREES) != \
			trigger_details.get(TRIGGER_DEGREES):
		is_valid = false

	# Card Flip filter checks
	if is_valid and card_scripts.get(FILTER_FACEUP) \
			and card_scripts.get(FILTER_FACEUP) != \
			trigger_details.get(TRIGGER_FACEUP):
		is_valid = false

	# Card move filter checks
	if is_valid and card_scripts.get(FILTER_SOURCE) \
			and card_scripts.get(FILTER_SOURCE) != \
			trigger_details.get(TRIGGER_SOURCE):
		is_valid = false
	if is_valid and card_scripts.get(FILTER_DESTINATION) \
			and card_scripts.get(FILTER_DESTINATION) != \
			trigger_details.get(TRIGGER_DESTINATION):
		is_valid = false

	# Card Tokens filter checks
	if is_valid and card_scripts.get(FILTER_COUNT) != null \
			and card_scripts.get(FILTER_COUNT) != \
			trigger_details.get(TRIGGER_NEW_COUNT):
		is_valid = false
	if is_valid and card_scripts.get(FILTER_COUNT_DIFFERENCE):
		var prev_count = trigger_details.get(TRIGGER_PREV_COUNT)
		var new_count = trigger_details.get(TRIGGER_NEW_COUNT)
		# Is true if the amount of tokens decreased
		if card_scripts.get(FILTER_COUNT_DIFFERENCE) == \
				TRIGGER_V_COUNT_INCREASED and prev_count > new_count:
			is_valid = false
		# Is true if the amount of tokens increased
		if card_scripts.get(FILTER_COUNT_DIFFERENCE) == \
				TRIGGER_V_COUNT_DECREASED and prev_count < new_count:
			is_valid = false

	# Token Name filter checks
	if is_valid and card_scripts.get("filter_" + TRIGGER_TOKEN_NAME) \
			and card_scripts.get("filter_" + TRIGGER_TOKEN_NAME) != \
			trigger_details.get(TRIGGER_TOKEN_NAME):
		is_valid = false

	# Counter Name filter checks
	if is_valid and card_scripts.get("filter_" + TRIGGER_COUNTER_NAME) \
			and card_scripts.get("filter_" + TRIGGER_COUNTER_NAME) != \
			trigger_details.get(TRIGGER_COUNTER_NAME):
		is_valid = false

	# Property Name filter checks
	# Typically used by alterants
	if is_valid and card_scripts.get("filter_" + TRIGGER_PROPERTY_NAME) \
			and card_scripts.get("filter_" + TRIGGER_PROPERTY_NAME) != \
			trigger_details.get(TRIGGER_PROPERTY_NAME):
		is_valid = false

	# Card spawn filter checks
	if is_valid and card_scripts.get(FILTER_CARD_NAME) \
			and card_scripts.get(FILTER_CARD_NAME) != \
			trigger_details.get(KEY_CARD_NAME):
		is_valid = false


	# Modified Property filter checks
	# See FILTER_MODIFIED_PROPERTIES documentation
	# If the trigger requires a filter on modified properties...
	if is_valid and card_scripts.get(FILTER_MODIFIED_PROPERTIES):
		# Then the filter entry will always contain a dictionary.
		# We extract that dictionary in mod_prop_dict.
		var mod_prop_dict = card_scripts.get(FILTER_MODIFIED_PROPERTIES)
		# Each signal for modified properties will provide the property name
		# We store that in signal_modified_property
		var signal_modified_property = trigger_details.get(TRIGGER_MODIFIED_PROPERTY_NAME)
		# If the property changed that is mentioned in the signal
		# does not match any of the properties requested in the filter,
		# then the trigger does not match
		if not signal_modified_property in mod_prop_dict.keys():
			is_valid = false
		else:
			# if the property changed that is mentioned in the signal
			# matches the properties requested in the filter
			# Then we also need to check if the filter specified
			# filtering on specific new or old values as well
			# To do that, we extract the possible new/old values needed
			# in the filter into mod_prop_values.
			# The key is signal_modified_property and it will contain another
			# dict, with the old and new values
			var mod_prop_values = mod_prop_dict.get(signal_modified_property)
			# Finally we check if it requires a specific new or old property
			# value. If it does, we check it against the signal details
			if mod_prop_values.get(FILTER_MODIFIED_PROPERTY_NEW_VALUE) != null \
					and mod_prop_values.get(FILTER_MODIFIED_PROPERTY_NEW_VALUE) != \
					trigger_details.get(TRIGGER_NEW_PROPERTY_VALUE):
				is_valid = false
			if mod_prop_values.get(FILTER_MODIFIED_PROPERTY_PREV_VALUE) != null \
					and mod_prop_values.get(FILTER_MODIFIED_PROPERTY_PREV_VALUE) != \
					trigger_details.get(TRIGGER_PREV_PROPERTY_VALUE):
				is_valid = false

	# Card Count on board filter check
	if is_valid and card_scripts.get(FILTER_PER_BOARDSEEK):
		var per_msg = perMessage.new(
				KEY_PER_BOARDSEEK,
				owner_card,
				card_scripts.get(FILTER_PER_BOARDSEEK))
		var found_count = per_msg.found_things
		var required_count = card_scripts.\
				get(FILTER_PER_BOARDSEEK).get(FILTER_CARD_COUNT)
		var comparison_type = card_scripts.get(FILTER_PER_BOARDSEEK).get(
				KEY_COMPARISON, get_default(KEY_COMPARISON))
		if not CFUtils.compare_numbers(
				found_count,
				required_count,
				comparison_type):
			is_valid = false

	# Card Count in CardContainer filter check
	if is_valid and card_scripts.get(FILTER_PER_TUTOR):
		var per_msg = perMessage.new(
				KEY_PER_TUTOR,
				owner_card,
				card_scripts.get(FILTER_PER_TUTOR))
		var found_count = per_msg.found_things
		var required_count = card_scripts.\
				get(FILTER_PER_TUTOR).get(FILTER_CARD_COUNT)
		var comparison_type = card_scripts.get(FILTER_PER_TUTOR).get(
				KEY_COMPARISON, get_default(KEY_COMPARISON))
		if not CFUtils.compare_numbers(
				found_count,
				required_count,
				comparison_type):
			is_valid = false
	return(is_valid)


# Returns true  if the card properties match against filters specified in
# the provided card_scripts or if no card property filters were defined.
# Otherwise returns false.
static func check_properties(card, property_filters: Dictionary) -> bool:
	var card_matches := true
	var comparison_type : String = property_filters.get(
			KEY_COMPARISON, get_default(KEY_COMPARISON))
	for property in property_filters:
		if property == KEY_COMPARISON:
			continue
		if property in CardConfig.PROPERTIES_ARRAYS:
			# If it's an array, we assume they passed on element
			# of that array to check against the card properties
			if not property_filters[property] in card.get_property(property)\
					and comparison_type == "eq":
				card_matches = false
			# We use the "ne" as a "not in" operator for Arrays.
			elif property_filters[property] in card.get_property(property)\
					and comparison_type == "ne":
				card_matches = false
		elif property in CardConfig.PROPERTIES_NUMBERS:
			var comparison_value: int
			if typeof(property_filters[property]) == TYPE_INT:
				comparison_value = property_filters[property]
			# We support comparing against counters. We assume any string
			# value is a counter name
			else:
				comparison_value = cfc.NMAP.board.counters.get_counter(
						property_filters[property])
			if not CFUtils.compare_numbers(
					card.get_property(property),
					comparison_value,
					comparison_type):
				card_matches = false
		else:
			if not CFUtils.compare_strings(
					property_filters[property],
					card.get_property(property),
					comparison_type):
				card_matches = false
	return(card_matches)


# Returns true if the card tokens match against filters specified in
# the provided card_scripts, of if no token filters were requested.
# Otherwise returns false.
static func check_token_filter(card, token_states: Array) -> bool:
	# Each array element, is an individual token name
	# for which to check against.
	var card_matches := true
	# Token filters always contain an array of token states
	for token_state in token_states:
		var comparison_type : String = token_state.get(
				KEY_COMPARISON, get_default(KEY_COMPARISON))
		if token_state.get("filter_" + TRIGGER_TOKEN_NAME):
			var token = card.tokens.get_token(
					token_state.get("filter_" + TRIGGER_TOKEN_NAME))
			if not token:
				if token_state.get(FILTER_COUNT):
					match comparison_type:
						"eq","ge":
							if token_state.get(FILTER_COUNT) != 0:
								card_matches = false
						"gt":
							card_matches = false
				else:
					card_matches = false
			elif token_state.get(FILTER_COUNT):
				if not CFUtils.compare_numbers(
						token.count,
						token_state.get(FILTER_COUNT),
						comparison_type):
					card_matches = false
	return(card_matches)


# Returns true if the rotation of the card matches the specified filter
# or the filter key was not defined. Otherwise returns false.
static func check_rotation_filter(card, rotation_state: int) -> bool:
	var card_matches := true
	# Card rotation does not support checking for not-equal
	if rotation_state != card.card_rotation:
		card_matches = false
	return(card_matches)


# Returns true if the faceup state of the card matches the specified filter
# or the filter key was not defined. Otherwise returns false.
static func check_faceup_filter(card, flip_state: bool) -> bool:
	var card_matches := true
	if flip_state != card.is_faceup:
		card_matches = false
	return(card_matches)


# Returns true if the faceup state of the card matches the specified filter
# or the filter key was not defined. Otherwise returns false.
static func check_parent_filter(card, parent: Node) -> bool:
	var card_matches := true
	if parent != card.get_parent():
		card_matches = false
	return(card_matches)


# Check if the card is a valid subject or trigger, according to its state.
static func check_validity(card, card_scripts, type := "trigger") -> bool:
	var card_matches := true
	# We use the type of seek we're doing
	# To know which dictionary property to pass for the required dict
	# This way a script can be limited on more than one thing according to
	# state. For example limit on the state of the trigger card
	# and the state of the subject cards.
	if card and card_scripts.get(FILTER_STATE + type):
		# each "filter_state_" FILTER is an array.
		# Each element in this array is dictionary of "AND" conditions
		# The filter will fail, only if ALL the or elements in this array
		# fail to match.
		var state_filters_array : Array = card_scripts.get(FILTER_STATE + type)
		# state_limits is the variable which will hold the dictionary
		# detailing which card state which the subjects must match
		# to satisfy this filter
		for state_filters in state_filters_array:
			card_matches = true
			for filter in state_filters:
				# We check with like this, as it allows us to provide an "AND"
				# check, by simply apprending something into the state string
				# I.e. if we have filter_properties and filter_properties2
				# It will treat these two states as an "AND"
				if FILTER_PROPERTIES in filter\
						and not check_properties(card, state_filters[filter]):
					card_matches = false
				elif FILTER_TOKENS in filter\
						and not check_token_filter(card, state_filters[filter]):
					card_matches = false
				elif filter == FILTER_DEGREES\
						and not check_rotation_filter(card,state_filters[filter]):
					card_matches = false
				# There's no possible "AND" state for a boolean filter.
				elif filter == FILTER_FACEUP\
						and not check_faceup_filter(card,state_filters[filter]):
					card_matches = false
				# There's no possible "AND" state for a boolean filter.
				elif filter == FILTER_PARENT\
						and not check_parent_filter(card,state_filters[filter]):
					card_matches = false
			# If at least one of our "or" array elements matches,
			# We do not need to check the others.
			if card_matches:
				break
	return(card_matches)
