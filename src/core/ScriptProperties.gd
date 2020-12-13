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

# Determines which card, if any, this script will try to affect.
#
# See the `KEY_SUBJECT_V_` consts for the possible values for this key
#
# If key does not exist, we set value to [], assuming there's no subjects
# in the task.
const KEY_SUBJECT := "subject"
# * If this is the value of the "subject" key,
# we initiate targetting from the owner card
const KEY_SUBJECT_V_TARGET := "target"
# * If this is the value of the "subject" key,
# then the task affects the owner card only.
const KEY_SUBJECT_V_SELF := "self"
# * If this is the value of the "subject" key,
# then we search all cards on the table
# by node order, and return candidates equal to KEY_SUBJECT_COUNT
# that match the filters
#
# This allows us to make tasks which will affect more than 1 card at
# the same time (e.g. "All Soldiers")
const KEY_SUBJECT_V_BOARDSEEK := "boardseek"
# * If this is the value of the "subject" key,
# then we search all cards on the specified
# pile by node order, and pick the first candidate that matches the filter
const KEY_SUBJECT_V_TUTOR := "tutor"
# * If this is the value of the "subject" key,
# then we pick the card on the specified
# source pile by its index among other cards.
const KEY_SUBJECT_V_INDEX := "index"
# * If this is the value of the "subject" key,
# then we use the subject specified in the previous task
const KEY_SUBJECT_V_PREVIOUS := "previous"
# Used when we're seeking a card
# to limit the amount to retrieve to this amount
# Work with the following task/key combinations:
# * move_card_cont_to_board
#   * KEY_SUBJECT_V_TUTOR
#   * KEY_SUBJECT_V_INDEX
# * move_card_cont_to_cont
#   * KEY_SUBJECT_V_TUTOR
#   * KEY_SUBJECT_V_INDEX
# * move_card_to_container
#   * KEY_SUBJECT_V_BOARDSEEK
# * move_card_to_board
#   * KEY_SUBJECT_V_BOARDSEEK
# Default is to seek only 1 card.
# when used in combination with KEY_SUBJECT_V_BOARDSEEK value can
# also be KEY_SUBJECT_COUNT_V_ALL which will simply set all cards
# that match the filters as subjects
const KEY_SUBJECT_COUNT := "subject_count"
# When specified as the value of KEY_SUBJECT_COUNT, will retrieve as many
# cards as match the criteria.
# Useful with the following KEY/VALUE combinations
# * move_card_cont_to_board
#   * KEY_SUBJECT_V_TUTOR
# * move_card_cont_to_cont
#   * KEY_SUBJECT_V_TUTOR
# * move_card_to_container
#   * KEY_SUBJECT_V_BOARDSEEK
# * move_card_to_board
#   * KEY_SUBJECT_V_BOARDSEEK
const KEY_SUBJECT_COUNT_V_ALL := "all"
# This key is used to mark a task as being a cost requirement before the
# rest of the defined tasks can execute.
#
# If any tasks marked as costs will not be able to fulfil, then the whole
# script is not executed.
#
# Currently the following tasks support being set as costs:
# * rotate_card
# * flip_card
# * mod_tokens
# * move_card_cont_to_cont
# * move_card_cont_to_board
const KEY_IS_COST := "is_cost"
# Used when a script is triggered by a signal.
#
# Limits the execution depending on the triggering card. Value options are:
# * "self": Triggering card has to be the owner of the script
# * "another": Triggering card has to not be the owner of the script
# * "any" (default): Will execute regardless of the triggering card.
const KEY_TRIGGER := "trigger"
# Used when a script is using the rotate_card task
#
# These are the degress in multiples of 90, that the subjects will be rotated.
const KEY_DEGREES := "degrees"
# Used when a script is using the flip_card task. Values are:
# * true: The card will be set face-up
# * false: The card will be set face-down
const KEY_SET_FACEUP := "set_faceup"
# Used when a script is using the modify_properties task.
# The value is supposed to be a dictionary of `"property name": value` entries
const KEY_MODIFY_PROPERTIES := "set_properties"
# Used when a script is using one of the following tasks
# * move_card_cont_to_cont
# * move_card_cont_to_board
#
# Specifies the source container to pick the card from
const KEY_SRC_CONTAINER := "src_container"
# Used when a script is using one of the following tasks
# * move_card_to_container
# * move_card_cont_to_cont
# * shuffle_container
#
# Specifies the destination container to manipulate
const KEY_DEST_CONTAINER := "dest_container"
# Used when we're seeking a card inside a [CardContainer]
# in one of the following tasks
# * move_card_cont_to_board
# * move_card_cont_to_cont
#
# Default is to seek card at index 0
const KEY_SUBJECT_INDEX := "subject_index"
# Special entry to be used with KEY_SUBJECT_INDEX instead of an integer
# If specified, explicitly looks for the top "card" of a pile
const KEY_SUBJECT_INDEX_V_TOP := "top"
# Special entry to be used with KEY_SUBJECT_INDEX instead of an integer
# If specified, explicitly looks for the "bottom" card of a pile
const KEY_SUBJECT_INDEX_V_BOTTOM := "bottom"
# Used when placing a card inside a [CardContainer]
# in one of the follwing tasks
# * move_card_to_container
# * move_card_cont_to_cont
#
# When -1 is defined, it is placed on the last position
const KEY_DEST_INDEX := "dest_index"
# Used when a script is using one of the following tasks
# * move_card_to_board
# * move_card_cont_to_board
#
# If Vector2(-1,-1) is specified, it uses the mouse position
# which obviously not good for scripts
const KEY_BOARD_POSITION := "board_position"
# Used when a script is using the mod_tokens task
#
# It specifies if we're modifying the existing amount
# or setting it to the exact one
const KEY_TOKEN_SET_TO_MOD := "set_to_mod"
# Used when a script is using the mod_tokens task
#
# It specifies the name of the token we're modifying
const KEY_TOKEN_NAME := "token_name"
# Used when a script is using the mod_tokens task
#
# It specifies the amount we're setting/modifying
# or setting it to the exact one
const KEY_TOKEN_MODIFICATION := "modification"
# Used when a script is using the spawn_card task
#
# This is the path to the card template scene to use for this card
const KEY_CARD_SCENE := "card_scene"
# Used by the "ask_integer" task. Specifies the minimum value the number
# needs to have
const KEY_ASK_INTEGER_MIN := "ask_int_min"
# Used by the "ask_integer" task. Specifies the maximum value the number
# needs to have
const KEY_ASK_INTEGER_MAX := "ask_int_max"
# This is a versatile value that can be inserted into any various keys
# when a task needs to use a previously inputed integer.
# When detected ,the task will retrieve the stored number and use it as specified
#
# The following keys support this value
# * KEY_TOKEN_MODIFICATION
# * KEY_SUBJECT_COUNT (only for specific tasks, see documentation)
const VALUE_RETRIEVE_INTEGER := "retrieve_integer"
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

# Filter used for checking against Card.properties
#
# This is open ended in the end, as the check can be run either
# against the trigger card, or the subjects card
# see _check_properties()

const FILTER_PROPERTIES := "filter_properties_"
# Filter used in for checking against TRIGGER_DEGREES
const FILTER_DEGREES := "filter_degrees"
# Filter for checking against TRIGGER_FACEUP
const FILTER_FACEUP := "filter_faceup"
# Filter for checking against TRIGGER_SOURCE
const FILTER_SOURCE := "filter_source"
# Filter for checking against TRIGGER_DESTINATION
const FILTER_DESTINATION := "filter_destination"
# Filter used for checking against TRIGGER_NEW_TOKEN_VALUE
const FILTER_TOKEN_COUNT := "filter_token_count"
#  Filter compared against
# * TRIGGER_V_TOKENS_INCREASED
# * TRIGGER_V_TOKENS_DECREASED
const FILTER_TOKEN_DIFFERENCE := "filter_token_difference"
# Filter used for checking against TRIGGER_TOKEN_NAME
const FILTER_TOKEN_NAME := "filter_token_name"
# Filter key used for checking against card_properties_modified details.
#
# Checking for modified properties is a bit trickier than other filters
# A signal emited from modified properties, will include as values the
# property name changed, and its new and old values.
#
# The filter specified in the card script definition, will have
# as the requested property filter, a dictionary inside the card_scripts
# with the key "filter_modified_properties".
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
# Filter used for checking against TRIGGER_NEW_PROPERTY_VALUE
const FILTER_MODIFIED_PROPERTY_NEW_VALUE := "new_value"
# Filter used for checking against TRIGGER_PREV_PROPERTY_VALUE
const FILTER_MODIFIED_PROPERTY_PREV_VALUE := "previous_value"


#---------------------------------------------------------------------
# Signal Properties
#
# The below are all the possible dictionary keys send in the dictionary
# passed by a card trigger signal (See Card signals)
#
# Most of them are only relevant for a specific task type
#---------------------------------------------------------------------

# Filter value sent by the trigger Card `card_rotated` signal.
#
# These are the degress in multiples of 90, that the subjects was rotated.
const TRIGGER_DEGREES := "degrees"
# Filter value sent by the trigger Card `card_flipped` signal.
#
# This is the facing of trigger.
# * true: Trigger turned face-up
# * false: Trigger turned face-down
const TRIGGER_FACEUP := "is_faceup"
# Filter value sent by the trigger Card `card_properties_modified` signal.
#
# This is the property name
const TRIGGER_MODIFIED_PROPERTY_NAME := "property_name"
# Filter value sent by the trigger Card `card_properties_modified` signal.
#
# This is the current value of the property.
const TRIGGER_NEW_PROPERTY_VALUE := "new_property_value"
# Filter value sent by the trigger Card `card_properties_modified` signal.
#
# This is the value the property had before it was modified
const TRIGGER_PREV_PROPERTY_VALUE := "previous_property_value"

# Filter value sent by one of the trigger Card's following signals:
# * card_moved_to_board
# * card_moved_to_pile
# * card_moved_to_hand
# The value will be the node name the Card left
const TRIGGER_SOURCE := "source"
# Filter value sent by one of the trigger [Card]'s following signals:
# * card_moved_to_board
# * card_moved_to_pile
# * card_moved_to_hand
# The value will be the node name the Card moved to
const TRIGGER_DESTINATION := "destination"
# Filter value sent by the trigger Card `card_token_modified` signal.
#
# This is the current value of the token.
# If token was removed value will be 0
const TRIGGER_NEW_TOKEN_VALUE := "new_token_value"
# Filter value sent by the trigger Card `card_token_modified` signal.
#
# This is the value the token had before it was modified
# If token was removed value will be 0
const TRIGGER_PREV_TOKEN_VALUE := "previous_token_value"
# Filter value sent by the trigger Card `card_token_modified` signal.
#
# This is the value of the token name modified
const TRIGGER_TOKEN_NAME = "token_name"
# Filter value sent by the following signals.
# * card_attached
# * card_unattached
# It contains the host object onto which this card attached
# of from which it unattached
const TRIGGER_HOST = "host"


#---------------------------------------------------------------------
# Signal Values
#
# Some filter check signals against constants. They are defined below
#---------------------------------------------------------------------

# Value is sent by trigger when new token count is higher than old token count.
# Compared against FILTER_TOKEN_DIFFERENCE
const TRIGGER_V_TOKENS_INCREASED := "increased"
# Value is sent by trigger when new token count is lower than old token count.
# Compared against FILTER_TOKEN_DIFFERENCE
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
		KEY_TOKEN_SET_TO_MOD:
			default = false
		KEY_TOKEN_MODIFICATION:
			default = 1
		KEY_IS_OPTIONAL:
			default = false
		KEY_MODIFY_PROPERTIES:
			default = {}
		KEY_SUBJECT_COUNT:
			default = 1
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
	var is_valid := check_properties(trigger_card, card_scripts, "trigger")

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


# Checks the provided card properties against filters specified in
# the provided card_scripts.
#
# Returns true if all the filters match the card properties.
# Otherwise returns false.
static func check_properties(card, card_scripts, type := "trigger") -> bool:
	var card_matches := true
	# Card properties filter checks. We use the type of seek we're doing
	# To know which dictionary property to pass for the required dict
	# This way a script can be limited on more than one thing according to
	# properties. For example limit on the properties of the trigger card
	# and the properties of the subjects card.
	if card_scripts.get(FILTER_PROPERTIES + type):
		# prop_limits is the variable which will hold the dictionary
		# detailing which card properties on the subjects must match
		# to satisfy this limit
		var prop_limits : Dictionary = card_scripts.get(FILTER_PROPERTIES + type)
		for property in prop_limits:
			if property in CardConfig.PROPERTIES_ARRAYS:
				# If it's an array, we assume they passed on element
				# of that array to check against the card properties
				if not prop_limits[property] in card.properties[property]:
					card_matches = false
			else:
				if prop_limits[property] != card.properties[property]:
					card_matches = false
	return(card_matches)
