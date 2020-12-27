# SP stands for "ScriptProperties".
#
# This class provides a library for constants which are used a key values
# in the Card Script Definition
#
# It also provides a few static functions for comparing filters
class_name SP
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
# If key does not exist, we set value to [], assuming there's no subjects
# in the task.
const KEY_SUBJECT := "subject"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# we initiate targetting from the owner card
const KEY_SUBJECT_V_TARGET := "target"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then the task affects the owner card only.
const KEY_SUBJECT_V_SELF := "self"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we search all cards on the table
# by node order, and return candidates equal to
# [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT) that match the filters.
#
# This allows us to make tasks which will affect more than 1 card at
# the same time (e.g. "All Soldiers")
const KEY_SUBJECT_V_BOARDSEEK := "boardseek"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we search all cards on the specified
# pile by node order, and pick the first candidate that matches the filter
const KEY_SUBJECT_V_TUTOR := "tutor"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we pick the card on the specified
# source pile by its index among other cards.
const KEY_SUBJECT_V_INDEX := "index"
# * If this is the value of the [KEY_SUBJECT](#KEY_SUBJECT) key,
# then we use the subject specified in the previous task
const KEY_SUBJECT_V_PREVIOUS := "previous"
# Value Type: Dynamic (Default = 1)
# * int
# * [KEY_SUBJECT_COUNT_V_ALL](#KEY_SUBJECT_COUNT_V_ALL)
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
#
# Used when we're seeking a card
# to limit the amount to retrieve to this amount
# Works with the following tasks and [KEY_SUBJECT](#KEY_SUBJECT) values:
# * [KEY_SUBJECT_V_BOARDSEEK](#KEY_SUBJECT_V_BOARDSEEK)
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
# * [KEY_SUBJECT_V_INDEX](#KEY_SUBJECT_V_INDEX)
const KEY_SUBJECT_COUNT := "subject_count"
# When specified as the value of [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT),
# will retrieve as many cards as match the criteria.
#
# Useful with the following VALUES:
# * [KEY_SUBJECT_V_BOARDSEEK](#KEY_SUBJECT_V_BOARDSEEK)
# * [KEY_SUBJECT_V_TUTOR](#KEY_SUBJECT_V_TUTOR)
const KEY_SUBJECT_COUNT_V_ALL := "all"
# Value Type: bool.
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
# * [move_card_to_container](ScriptingEngine#move_card_to_container)
# * [move_card_to_board](ScriptingEngine#move_card_to_board)
const KEY_IS_COST := "is_cost"
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
# Value Type: bool (Default = false).
#
# Used when a script is using one of the following tasks:
# * [mod_tokens](ScriptingEngine#mod_tokens)
#
# It specifies if we're modifying the existing amount
# or setting it to the exact one
const KEY_SET_TO_MOD := "set_to_mod"
# Value Type: String (Default = 1).
#
# Used when a script is using the [mod_tokens](ScriptingEngine#mod_tokens) task.
#
# It specifies the name of the token we're modifying
const KEY_TOKEN_NAME := "token_name"
# Value Type: Dynamic
# * int.
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
#
# Used when a script is using one of the following tasks:
# * [mod_tokens](ScriptingEngine#mod_tokens)
#
# It specifies the amount we're setting/modifying
# or setting it to the exact one
const KEY_MODIFICATION := "modification"
# Value Type: Dynamic (Default = 1).
# * int.
# * [VALUE_RETRIEVE_INTEGER](#VALUE_RETRIEVE_INTEGER)
#
# Used in conjunction with the following tasks
# * [spawn_card](ScriptingEngine#spawn_card)
# * [add_grid](ScriptingEngine#add_grid)
#
# specified how many of the "thing" done by the task, to perform.
const KEY_OBJECT_COUNT := "object_count"
# Value Type: String
#
# Used in conjunction with the following tasks
# * [spawn_card](ScriptingEngine#spawn_card)
# * [add_grid](ScriptingEngine#add_grid)
#
# This is the path to the scene we will add to the game.
const KEY_SCENE_PATH := "scene_path"
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
# "Draw 1 card for each card with 0 power on the board"
const VALUE_PER := "per_"
# Value Type: String
#
# This key is typically needed in combination with [KEY_PER_PROPERTY](#KEY_PER_PROPERTY)
# to specify which property to base the per upon. The property **has** to be
# a number.
const KEY_PROPERTY_NAME := "property_name"
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
# Value Type: String
# * "eq" (Defaut): Equal
# * "ne": Not equal (This can be used to againsr strings as well)
# * "gt": Greater than
# * "lt": Less than
# * "le": Less than or Equal
# * "ge": Geater than or equal
#
# Key is used typically to do numerical comparisons during filters involving
# numerical numbers.
#
# I.e. it allows to write the script for something like:
# "Destroy all Monsters with cost equal or higher than 3"
const KEY_COMPARISON := "comparison"
# This is a versatile value that can be inserted into any various keys
# when a task needs to use a previously inputed integer provided
# with a [ask_integer](ScriptingEngine#ask_integer) task.
# When detected ,the task will retrieve the stored number and use it as specified
#
# The following keys support this value
# * [KEY_MODIFICATION](#KEY_MODIFICATION)
# * [KEY_SUBJECT_COUNT](#KEY_SUBJECT_COUNT) (only for specific tasks, see documentation)
# * [KEY_OBJECT_COUNT](#KEY_OBJECT_COUNT) (only for specific tasks, see documentation)
const VALUE_RETRIEVE_INTEGER := "retrieve_integer"
# Value Type: bool (Default = false)
#
# Specifies whether this script or task can be skipped by the owner.
#
# This value needs to be prepended and placed
# depending on what it is making optional
#
# If it is making a sigle task optional, you need to add "task" at the end
# and place it inside a task definition
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
# If you want to make a whole script optional, then you need to place it on
# the same level as the state and append the state name
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
# If that task is a cost, it will also prevent subsequent tasks from firing
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
# This is open ended to be appended, as the check can be run either
# against the trigger card, or the subjects card.
#
# One of the following strings HAS to be appended at the end:
# * "trigger": Will only filter cards triggering this effect via signals.
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
const FILTER_PROPERTIES := "filter_properties"
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
# Filter used for checking against [TRIGGER_NEW_TOKEN_VALUE](#TRIGGER_NEW_TOKEN_VALUE)
# and in [check_state](#check_state)
const FILTER_TOKEN_COUNT := "filter_token_count"
# Value Type: String
# * [TRIGGER_V_TOKENS_INCREASED](#TRIGGER_V_TOKENS_INCREASED)
# * [TRIGGER_V_TOKENS_DECREASED](#TRIGGER_V_TOKENS_DECREASED)
const FILTER_TOKEN_DIFFERENCE := "filter_token_difference"
# Value Type: String.
#
# Filter used for checking against [TRIGGER_TOKEN_NAME](#TRIGGER_TOKEN_NAME)
# and in [check_state](#check_state)
const FILTER_TOKEN_NAME := "filter_token_name"
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


#---------------------------------------------------------------------
# Signal Properties
#
# The below are all the possible dictionary keys send in the dictionary
# passed by a card trigger signal (See Card signals)
#
# Most of them are only relevant for a specific task type
#---------------------------------------------------------------------

# Value Type: int.
#
# Filter value sent by the trigger Card `card_rotated` [signal](Card#signals).
#
# These are the degress in multiples of 90, that the subjects was rotated.
const TRIGGER_DEGREES := "degrees"
# Value Type: bool.
#
# Filter value sent by the trigger Card `card_flipped` [signal](Card#signals).
#
# This is the facing of trigger.
# * true: Trigger turned face-up
# * false: Trigger turned face-down
const TRIGGER_FACEUP := "is_faceup"
# Value Type: String.
#
# Filter value sent by the trigger `card_properties_modified` [signal](Card#signals).
#
# This is the property name
const TRIGGER_MODIFIED_PROPERTY_NAME := "property_name"
# Value Type: String.
#
# Filter value sent by the trigger `card_properties_modified` [signal](Card#signals).
#
# This is the current value of the property.
const TRIGGER_NEW_PROPERTY_VALUE := "new_property_value"
# Value Type: String.
#
# Filter value sent by the trigger `card_properties_modified` [signal](Card#signals).
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
# Filter value sent by the trigger Card `card_token_modified` [signal](Card#signals).
#
# This is the current value of the token.
# If token was removed value will be 0
const TRIGGER_NEW_TOKEN_VALUE := "new_token_value"
# Value Type: int.
#
# Filter value sent by the trigger Card `card_token_modified` [signal](Card#signals).
#
# This is the value the token had before it was modified
# If token was removed value will be 0
const TRIGGER_PREV_TOKEN_VALUE := "previous_token_value"
# Value Type: String.
#
# Filter value sent by the trigger Card `card_token_modified` [signal](Card#signals).
#
# This is the value of the token name modified
const TRIGGER_TOKEN_NAME = "token_name"
# Value Type: Card.
#
# Filter value sent by the following [signals](Card#signals).
# * card_attached
# * card_unattached
# It contains the host object onto which this card attached
# or from which it unattached
const TRIGGER_HOST = "host"


#---------------------------------------------------------------------
# Signal Values
#
# Some filter check signals against constants. They are defined below
#---------------------------------------------------------------------

# Value is sent by trigger when new token count is higher than old token count.
# Compared against [FILTER_TOKEN_DIFFERENCE](#FILTER_TOKEN_DIFFERENCE)
const TRIGGER_V_TOKENS_INCREASED := "increased"
# Value is sent by trigger when new token count is lower than old token count.
# Compared against [FILTER_TOKEN_DIFFERENCE](#FILTER_TOKEN_DIFFERENCE)
const TRIGGER_V_TOKENS_DECREASED := "decreased"


# Returns the default value any script definition key should have
static func get_default(property: String):
	var default
	# for property details, see const definitionts
	match property:
		KEY_IS_COST:
			default = false
		KEY_TRIGGER:
			default = "any"
		KEY_SUBJECT_INDEX:
			default = 0
		KEY_DEST_INDEX:
			default = -1
		KEY_BOARD_POSITION:
			default = Vector2(-1,-1)
		KEY_SET_TO_MOD:
			default = false
		KEY_MODIFICATION:
			default = 1
		KEY_IS_OPTIONAL:
			default = false
		KEY_MODIFY_PROPERTIES:
			default = {}
		KEY_SUBJECT_COUNT, KEY_OBJECT_COUNT:
			default = 1
		KEY_GRID_NAME:
			default = ""
		KEY_COMPARISON:
			default = "eq"
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
		signal_details) -> bool:
	# Checking card properties is its own function as it might be
	# called from other places as well
	var is_valid := check_validity(trigger_card, card_scripts, "trigger")

	# Here we check that the trigger matches the _request_ for trigger
	# A trigger which requires "another" card, should not trigger
	# when itself causes the effect.
	# For example, a card which rotates itself whenever another card
	# is rotated, should not automatically rotate when itself rotates.
	if card_scripts.get("trigger") == "self" and trigger_card != owner_card:
		is_valid = false
	if card_scripts.get("trigger") == "another" and trigger_card == owner_card:
		is_valid = false

	# Card Rotation filter checks
	if card_scripts.get(FILTER_DEGREES) \
			and card_scripts.get(FILTER_DEGREES) != \
			signal_details.get(TRIGGER_DEGREES):
		is_valid = false

	# Card Flip filter checks
	if card_scripts.get(FILTER_FACEUP) \
			and card_scripts.get(FILTER_FACEUP) != \
			signal_details.get(TRIGGER_FACEUP):
		is_valid = false

	# Card move filter checks
	if card_scripts.get(FILTER_SOURCE) \
			and card_scripts.get(FILTER_SOURCE) != \
			signal_details.get(TRIGGER_SOURCE):
		is_valid = false
	if card_scripts.get(FILTER_DESTINATION) \
			and card_scripts.get(FILTER_DESTINATION) != \
			signal_details.get(TRIGGER_DESTINATION):
		is_valid = false

	# Card Tokens filter checks
	if card_scripts.get(FILTER_TOKEN_COUNT) \
			and card_scripts.get(FILTER_TOKEN_COUNT) != \
			signal_details.get(TRIGGER_NEW_TOKEN_VALUE):
		is_valid = false
	if card_scripts.get(FILTER_TOKEN_DIFFERENCE):
		var prev_count = signal_details.get(TRIGGER_PREV_TOKEN_VALUE)
		var new_count = signal_details.get(TRIGGER_NEW_TOKEN_VALUE)
		# Is true if the amount of tokens decreased
		if card_scripts.get(FILTER_TOKEN_DIFFERENCE) == \
				TRIGGER_V_TOKENS_INCREASED and prev_count > new_count:
			is_valid = false
		# Is true if the amount of tokens increased
		if card_scripts.get(FILTER_TOKEN_DIFFERENCE) == \
				TRIGGER_V_TOKENS_DECREASED and prev_count < new_count:
			is_valid = false
	if card_scripts.get(FILTER_TOKEN_NAME) \
			and card_scripts.get(FILTER_TOKEN_NAME) != \
			signal_details.get(TRIGGER_TOKEN_NAME):
		is_valid = false
	# Modified Property filter checks
	# See FILTER_MODIFIED_PROPERTIES documentation
	# If the trigger requires a filter on modified properties...
	if card_scripts.get(FILTER_MODIFIED_PROPERTIES):
		# Then the filter entry will always contain a dictionary.
		# We extract that dictionary in mod_prop_dict.
		var mod_prop_dict = card_scripts.get(FILTER_MODIFIED_PROPERTIES)
		# Each signal for modified properties will provide the property name
		# We store that in signal_modified_property
		var signal_modified_property = signal_details.get(TRIGGER_MODIFIED_PROPERTY_NAME)
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
			if mod_prop_values.get(FILTER_MODIFIED_PROPERTY_NEW_VALUE) \
					and mod_prop_values.get(FILTER_MODIFIED_PROPERTY_NEW_VALUE) != \
					signal_details.get(TRIGGER_NEW_PROPERTY_VALUE):
				is_valid = false
			if mod_prop_values.get(FILTER_MODIFIED_PROPERTY_PREV_VALUE) \
					and mod_prop_values.get(FILTER_MODIFIED_PROPERTY_PREV_VALUE) != \
					signal_details.get(TRIGGER_PREV_PROPERTY_VALUE):
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
			if not property_filters[property] in card.properties[property]\
					and comparison_type == "eq":
				card_matches = false
			# We use the "ne" as a "not in" operator for Arrays.
			elif property_filters[property] in card.properties[property]\
					and comparison_type == "ne":
				card_matches = false
		elif property in CardConfig.PROPERTIES_NUMBERS:
			if not CFUtils.compare_numbers(
					card.properties[property],
					property_filters[property],
					comparison_type):
				card_matches = false
		else:
			if not CFUtils.compare_strings(
					property_filters[property],
					card.properties[property],
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
		if token_state.get(FILTER_TOKEN_NAME):
			var token = card.tokens.get_token(
					token_state.get(FILTER_TOKEN_NAME))
			if not token:
				if token_state.get(FILTER_TOKEN_COUNT):
					match comparison_type:
						"eq","ge":
							if token_state.get(FILTER_TOKEN_COUNT) != 0:
								card_matches = false
						"gt":
							card_matches = false
				else:
					card_matches = false
			elif token_state.get(FILTER_TOKEN_COUNT):
				if not CFUtils.compare_numbers(
						token.count,
						token_state.get(FILTER_TOKEN_COUNT),
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


# Check if the card is a valid subject or trigger, according to its state.
static func check_validity(card, card_scripts, type := "trigger") -> bool:
	var card_matches := true
	# We use the type of seek we're doing
	# To know which dictionary property to pass for the required dict
	# This way a script can be limited on more than one thing according to
	# state. For example limit on the state of the trigger card
	# and the state of the subject cards.
	if card_scripts.get(FILTER_STATE + type):
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
				elif FILTER_DEGREES in filter\
						and not check_rotation_filter(card,state_filters[filter]):
					card_matches = false
				# There's no possible "AND" state for a boolean filter.
				elif filter == FILTER_FACEUP\
						and not check_faceup_filter(card,state_filters[filter]):
					card_matches = false
			# If at least one of our "or" array elements matches,
			# We do not need to check the others.
			if card_matches:
				break
	return(card_matches)
