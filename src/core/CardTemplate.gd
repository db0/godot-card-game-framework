# A basic card object which includes functionality for handling its own
# placement and focus.
#
# This class is meant to be used as the basis for your card scripting
# Simply make your card scripts extend this class and you'll have all the
# provided scripts available.
# If your card node type is not Area2D, make sure you change the extends type.
class_name Card
extends Area2D

# All the Card's Finite State Machine states
#
# This simply is a way to refer to the values with a human-readable name.
#
# See _process_card_state()
enum CardState {
	IN_HAND					#0
	FOCUSED_IN_HAND			#1
	MOVING_TO_CONTAINER		#2
	REORGANIZING			#3
	PUSHED_ASIDE			#4
	DRAGGED					#5
	DROPPING_TO_BOARD		#6
	ON_PLAY_BOARD			#7
	FOCUSED_ON_BOARD		#8
	DROPPING_INTO_PILE 		#9
	IN_PILE					#10
	IN_POPUP				#11
	FOCUSED_IN_POPUP		#12
	VIEWPORT_FOCUS			#13
}

# Used to spawn CardChoices. We have to add the consts together
# before passing to the preload, or the parser complains.
const _CARD_CHOICES_SCENE_FILE = CFConst.PATH_CORE + "CardChoices.tscn"
const _CARD_CHOICES_SCENE = preload(_CARD_CHOICES_SCENE_FILE)



# Emitted whenever the card is rotated
# The signal must send its name as well (in the trigger var)
# Because it's sent by the SignalPropagator to all cards and they use it
# To filter.
signal card_rotated(card,trigger,details)
# Emitted whenever the card flips up/down
signal card_flipped(card,trigger,details)
# Emitted whenever the card is viewed while face-down
signal card_viewed(card,trigger,details)
# Emited whenever the card is moved to the board
signal card_moved_to_board(card,trigger,details)
# Emited whenever the card is moved to a pile
signal card_moved_to_pile(card,trigger,details)
# Emited whenever the card is moved to a hand
signal card_moved_to_hand(card,trigger,details)
# Emited whenever the card's tokens are modified
# warning-ignore:unused_signal
signal card_token_modified(card,trigger,details)
# Emited whenever the card attaches to another
signal card_attached(card,trigger,details)
# Emited whenever the card unattaches from another
signal card_unattached(card,trigger,details)
# Emited whenever the card properties are modified
signal card_properties_modified(card,trigger,details)
# Emited whenever the card is targeted by another card.
# This signal is not fired by this card directly, but by the card
# doing the targeting.
# warning-ignore:unused_signal
signal card_targeted(card,trigger,details)

# We cannot preload the scripting engine as a const for the same reason
# We cannot refer to it via class name.
#
# If we do, it is parsed by the compiler who then considers it
# a cyclic reference as the scripting engine refers back to the Card class.
var scripting_engine = load(CFConst.PATH_CORE + "ScriptingEngine.gd")

export var properties : Dictionary
# We export this variable to the editor to allow us to add scripts to each card
# object directly instead of only via code.
#
# If this variable is set, it takes precedence over scripts
# found in `CardScriptDefinitions.gd`
#
# See `CardScriptDefinitions.gd` for the proper format of a scripts dictionary
export var scripts : Dictionary
# If true, the card can be attached to other cards and will follow
# their host around the table. The card will always return to its host
# when dragged away
export var is_attachment := false setget set_is_attachment, get_is_attachment
# If true, the card front will be displayed when mouse hovers over the card
# while it's face-down
export var is_viewed  := false setget set_is_viewed, get_is_viewed
# Specifies the card rotation in increments of 90 degrees
export(int, 0, 270, 90) var card_rotation  := 0 setget set_card_rotation, get_card_rotation
# This is **the** authorative name for this node
#
# If not set, will be set to the value of the Name label in the front.
# if that is also not set, will be set.
# to the human-readable value of the "name" node property.
export var card_name : String setget set_card_name, get_card_name

# Starting state for each card
var state : int = CardState.IN_PILE
# If this card is hosting other cards,
# this list retains links to their objects in order.
var attachments := []
# If this card is set as an attachment to another card,
# this tracks who its host is.
var current_host_card : Card = null
# If true, the card will be displayed faceup. If false, it will be facedown
var is_faceup := true setget set_is_faceup, get_is_faceup
# Used for animating the card.
var _target_position: Vector2
# Used for animating the card.
var _target_rotation: float
# Used to avoid the focus animation repeating once it's completed.
var _focus_completed: bool = false
# We use this to know at which stage of fancy movement this is.
var _fancy_move_second_part := false
# We use this to track multiple cards
# when our card is about to drop onto or target them
var _potential_cards := []
var _potential_containers := []

# Used for picking a card to start the compiler on
var _debugger_hook := false
# Debug for stuck tweens
var _tween_stuck_time = 0

onready var _tween = $Tween
onready var _flip_tween = $Control/FlipTween
onready var _control = $Control
onready var _card_text = $Control/Front/CardText
# The node which has the image of the card back
# And the methods which are used for its potential animation.
onready var card_back = $Control/Back
# The node which hosts all manipulation buttons belonging to this card
# as well as methods to hide/show them, and connect them to this card.
onready var buttons= $Control/ManipulationButtons
# The node which hosts all tokens belonging to this card
# as well as the methods retrieve them and to to hide/show their drawer.
onready var tokens = $Control/Tokens
# The node which controls the targeting arrow.
onready var targeting_arrow = $TargetLine
# The node which manipulates the highlight borders.
onready var highlight = $Control/Highlight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# The below call ensures out card_name variable is set.
	# Normally the setup() function should be used to set it,
	# but setting the name here as well ensures that a card can be also put on
	# The board without calling setup() and then use its hardcoded labels
	_init_card_name()
	# First we set the card to always pivot from its center.
	# We only rotate the Control node however, so the collision shape is not rotated
	# Looking for a better solution, but this is the best I have until now.
	$Control.rect_pivot_offset = $Control.rect_size/2
	# We set the card's Highlight to always extend 3 pixels over
	# Either side of the card. This way its border will appear
	# correctly when hovering over the card.
	highlight.rect_size = $Control.rect_size + Vector2(6,6)
	highlight.rect_position = Vector2(-3,-3)
	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_Card_area_entered")
	# warning-ignore:return_value_discarded
	connect("area_exited", self, "_on_Card_area_exited")

	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", self, "_on_Card_gui_input")

	cfc.signal_propagator.connect_new_card(self)


func _init_card_name():
	if not card_name:
		# If the variable has not been set on start
		# But the Name label has been set, we set our name to that instead
		if $Control/Front/CardText/Name.text != "":
			set_card_name($Control/Front/CardText/Name.text)
		else:
			# The node name changes depeding on how many other cards
			# with the same node name are siblings
			# We use this regex to discover the actual name
			var regex = RegEx.new()
			regex.compile("@{0,1}([\\w ]+)@{0,1}")
			var result = regex.search(name)
			var node_human_name = result.get_string(1)
			set_card_name(node_human_name)
	else:
		# If the variable has been set, we ensure label and node name
		# are matching
		set_card_name(card_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if $Tween.is_active() and not cfc.ut: # Debug code for catch potential Tween deadlocks
		_tween_stuck_time += delta
		if _tween_stuck_time > 5 and int(fmod(_tween_stuck_time,3)) == 2 :
			print("Tween Stuck for ",_tween_stuck_time,
					"seconds. Reports leftover runtime: ",$Tween.get_runtime ( ))
			$Tween.remove_all()
			_tween_stuck_time = 0
	else:
		_tween_stuck_time = 0
	_process_card_state()
	# Having to do all these checks due to godotengine/godot#16854
	if cfc._debug and not get_parent().is_in_group("piles"):
		var stateslist = [
			"IN_HAND",
			"FOCUSED_IN_HAND",
			"MOVING_TO_CONTAINER",
			"REORGANIZING",
			"PUSHED_ASIDE",
			"DRAGGED",
			"DROPPING_TO_BOARD",
			"ON_PLAY_BOARD",
			"FOCUSED_ON_BOARD",
			"DROPPING_INTO_PILE",
			"IN_PILE",
			"IN_POPUP",
			"FOCUSED_IN_POPUP",
			"VIEWPORT_FOCUS",
		]
		$Debug.visible = true
		$Debug/id.text = "ID:  " + str(self)
		$Debug/state.text = "STATE: " + stateslist[state]
		$Debug/index.text = "INDEX: " + str(get_index())
		$Debug/parent.text = "PARENT: " + str(get_parent().name)


# Triggers the focus-in effect on the card
func _on_Card_mouse_entered() -> void:
	# This triggers the focus-in effect on the card
	#print(state,":enter:",get_index(), ":", buttons._are_hovered()) # Debug
	#print($Control/Tokens/Drawer/VBoxContainer.rect_size) # debug
	match state:
		CardState.IN_HAND, CardState.REORGANIZING, CardState.PUSHED_ASIDE:
			if not cfc.card_drag_ongoing:
				#print("focusing:",get_my_card_index()) # debug
				interruptTweening()
				state = CardState.FOCUSED_IN_HAND
		CardState.ON_PLAY_BOARD:
			state = CardState.FOCUSED_ON_BOARD
		# The only way to mouse over a card in a pile, is when
		# it's in a the grid popup
		CardState.IN_POPUP:
			state = CardState.FOCUSED_IN_POPUP


func _input(event) -> void:
	if event is InputEventMouseButton and not event.is_pressed():
		if targeting_arrow.is_targeting:
			targeting_arrow.complete_targeting()
		if  event.get_button_index() == 1:
			# On depressed left mouse click anywhere on the board
			# We stop all attempts at dragging this card
			# We cannot do this in gui_input, because some thing
			# like the targetting arrow, will trigger dragging
			# because the click depress will not trigger on the card for some reason
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Control.set_default_cursor_shape(Input.CURSOR_ARROW)
			cfc.card_drag_ongoing = null

# A signal for whenever the player clicks on a card
func _on_Card_gui_input(event) -> void:
	if event is InputEventMouseButton:
		# because of https://github.com/godotengine/godot/issues/44138
		# we need to double check that the card which is receiving the
		# gui input, is actually the one with the highest index.
		# We use our mouse pointer which is tracking this info.
		if cfc.NMAP.board.mouse_pointer.current_focused_card \
				and self != cfc.NMAP.board.mouse_pointer.current_focused_card:
			cfc.NMAP.board.mouse_pointer.current_focused_card._on_Card_gui_input(event)
		# If the player left clicks, we need to see if it's a double-click
		# or a long click
		elif event.is_pressed() \
				and event.get_button_index() == 1 \
				and not buttons.are_hovered() \
				and not tokens.are_hovered():
			# If it's a double-click, then it's not a card drag
			# But rather it's script execution
			if event.doubleclick:
				cfc.card_drag_ongoing = null
				execute_scripts()
			# If it's a long click it might be because
			# they want to drag the card
			else:
				if state in [CardState.FOCUSED_IN_HAND,
						CardState.FOCUSED_ON_BOARD,
						CardState.FOCUSED_IN_POPUP]:
					# But first we check if the player does a long-press.
					# We don't want to start dragging the card immediately.
					cfc.card_drag_ongoing = self
					# We need to wait a bit to make sure the other card has a chance
					# to go through their scripts
					yield(get_tree().create_timer(0.1), "timeout")
					# If this variable is still set to true,
					# it means the mouse-button is still pressed
					# We also check if another card is already selected for dragging,
					# to prevent from picking 2 cards at the same time.
					if cfc.card_drag_ongoing == self:
						# While the mouse is kept pressed, we tell the engine
						# that a card is being dragged
						_start_dragging()
			# If the mouse button was released we drop the dragged card
			# This also means a card clicked once won't try to immediately drag
		elif not event.is_pressed() and event.get_button_index() == 1:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Control.set_default_cursor_shape(Input.CURSOR_ARROW)
			cfc.card_drag_ongoing = null
			match state:
				CardState.DRAGGED:
					# if the card was being dragged, it's index is very high
					# to always draw above other objects
					# We need to reset it to the default of 0
					z_index = 0
					var destination = cfc.NMAP.board
					if not _potential_containers.empty():
						destination = _potential_containers.back()
						_potential_containers.back().highlight.set_highlight(false)
					move_to(destination)
					_focus_completed = false
					#emit_signal("card_dropped",self)
		elif event.is_pressed() and event.get_button_index() == 2:
			targeting_arrow.initiate_targeting()
		elif not event.is_pressed() and event.get_button_index() == 2:
			targeting_arrow.complete_targeting()


# Triggers the focus-out effect on the card
func _on_Card_mouse_exited() -> void:
	# On exiting this node, we wait a tiny bit to make sure the mouse didn't
	# just enter a child button
	# If it did, then that button will immediately set a variable to let us know
	# not to restart the focus
	#print(state,":exit:",get_index()) # debug
	#print(buttons.are_hovered()) # debug
	match state:
		CardState.FOCUSED_IN_HAND:
			#_focus_completed = false
			# To avoid errors during fast player actions
			if get_parent().is_in_group("hands"):
				for c in get_parent().get_all_cards():
					# We need to make sure afterwards all card will return
					# to their expected positions
					# Therefore we simply stop all tweens and reorganize the whole hand
					c.interruptTweening()
					# This will also set the state to IN_HAND afterwards
					c.reorganize_self()
		CardState.FOCUSED_ON_BOARD:
			state = CardState.ON_PLAY_BOARD
		CardState.FOCUSED_IN_POPUP:
			state = CardState.IN_POPUP

# Hover button which rotates the card 90 degrees
func _on_Rot90_pressed() -> void:
# warning-ignore:return_value_discarded
	set_card_rotation(90, true)


# Hover button which rotates the card 180 degrees
func _on_Rot180_pressed() -> void:
# warning-ignore:return_value_discarded
	set_card_rotation(180, true)


# Hover button which flips the card facedown/faceup
func _on_Flip_pressed() -> void:
	# warning-ignore:return_value_discarded
	set_is_faceup(not is_faceup)


# Demo hover button which adds a selection of random tokens
func _on_AddToken_pressed() -> void:
	var valid_tokens := ['tech','gold coin','blood','plasma']
	# warning-ignore:return_value_discarded
	tokens.mod_token(valid_tokens[CFUtils.randi() % len(valid_tokens)], 1)


# Hover button which allows the player to view a facedown card
func _on_View_pressed() -> void:
	# warning-ignore:return_value_discarded
	set_is_viewed(true)


# Triggers when a card hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as hosts
func _on_Card_area_entered(area: Area2D) -> void:
	if (area as Card and is_attachment and not area in attachments):
		var card : Card = area
		# The below 'if', checks if the card we're hovering has already been considered
		# If it hasn't we add it to an array of all the cards we're hovering
		# onto at the moment, at the same time
		# But we only care for cards on the table, and only while this card is
		# the one being dragged
		if (not card in _potential_cards and
				card.get_parent() == cfc.NMAP.board and
				cfc.card_drag_ongoing == self):
			# We add the card to the list which tracks out simultaneous hovers
			_potential_cards.append(card)
			# We sort all potential cards by their index
			_potential_cards.sort_custom(CFUtils,"sort_index_ascending")
			# Finally we use a method which  handles changing highlights on the
			# top index card
			highlight.highlight_potential_card(CFConst.HOST_HOVER_COLOUR,
					_potential_cards)
	if area.get_class() == "CardContainer" \
			and not area in _potential_containers \
			and state == CardState.DRAGGED:
		var container = area
		_potential_containers.append(container)
		_potential_containers.sort_custom(CFUtils,"sort_card_containers")
		highlight.highlight_potential_container(CFConst.TARGET_HOVER_COLOUR,
				_potential_containers)


# Triggers when a card stops hovering over another
#
# It clears potential highlights and adjusts potential cards as hosts
func _on_Card_area_exited(area: Area2D) -> void:
	if area as Card:
		var card : Card = area
		# We only do any step if the card we exited was already considered and
		# was on the board
		# And only while this is the card being dragged
		if (card in _potential_cards and
				card.get_parent() == cfc.NMAP.board
				and cfc.card_drag_ongoing == self):
			# We remove the card we stopped hovering from the _potential_cards
			_potential_cards.erase(card)
			# And we explicitly hide its cards focus since we don't care about
			# it anymore
			card.highlight.set_highlight(false)
			# Finally, we make sure we highlight any other cards we're still hovering
			highlight.highlight_potential_card(CFConst.HOST_HOVER_COLOUR,
					_potential_cards)
	if area.get_class() == "CardContainer" \
			and area in _potential_containers \
			and state == CardState.DRAGGED:
		var container = area
		_potential_containers.erase(container)
		container.highlight.set_highlight(false)
		highlight.highlight_potential_container(CFConst.TARGET_HOVER_COLOUR,
				_potential_containers)




# This function handles filling up the card's labels according to its
# card definition dictionary entry.
func setup(cname: String) -> void:
	# The card name is the most important aspect.
	# We cannot use card_name as this var, as it's a global var
	set_card_name(cname)
	# The properties of the card should be already stored in cfc
	var read_properties = cfc.card_definitions.get(cname)
	for property in read_properties.keys():
		modify_property(property,read_properties[property], true)


func modify_property(property: String, value, is_init = false, check := false) -> int:
	var retcode: int
	if not property in properties.keys() and not is_init:
		retcode = CFConst.ReturnCode.FAILED
	elif properties.get(property) == value:
		retcode = CFConst.ReturnCode.OK
	else:
		# We store the values to send with the signal
		var previous_value
		if not is_init:
			previous_value = properties[property]
		retcode = CFConst.ReturnCode.CHANGED
		if not check and property == "Name":
			set_card_name(value)
		elif not check:
			properties[property] = value
			if not is_init:
				emit_signal("card_properties_modified",
						self, "card_properties_modified",
						{"property_name": property,
						"new_property_value": value,
						"previous_property_value": previous_value})
			# These are standard properties which is simple a String to add to the
			# label.text field
			if property in CardConfig.PROPERTIES_STRINGS:
				_set_label_text($Control/Front/CardText.get_node(property),
						value)
				# $Control/Front/CardText.get_node(label).text = properties[label]
				if value == "" :
					$Control/Front/CardText.get_node(property).visible = false
			# These are int or float properties which need to be converted
			# to a string with some formatting.
			#
			# In this demo, the format is defined as: "labelname: value"
			elif property in CardConfig.PROPERTIES_NUMBERS:
				_set_label_text($Control/Front/CardText.get_node(property),property
						+ ": " + str(value))
			# These are arrays of properties which are put in a label with a simple
			# Join character
			elif property in CardConfig.PROPERTIES_ARRAYS:
				_set_label_text($Control/Front/CardText.get_node(property),
						CFUtils.array_join(value,
						CFConst.ARRAY_PROPERTY_JOIN))
	return(retcode)


# Setter for _is_attachment
func set_is_attachment(value: bool) -> void:
	is_attachment = value


# Getter for _is_attachment
func get_is_attachment() -> bool:
	return is_attachment

# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# * Returns CFConst.ReturnCode.CHANGED if the card actually changed rotation
# * Returns CFConst.ReturnCode.OK if the card was already in the correct rotation
func set_is_faceup(value: bool, instant := false, check := false) -> int:
	var retcode: int
	if value == is_faceup:
		retcode = CFConst.ReturnCode.OK
	# We check if the parent is a valid instance
	# If it is not, this is a viewport dupe card that has not finished
	# it's ready() process
	elif not check and is_instance_valid(get_parent()):
		tokens.is_drawer_open = false
		# We make sure to remove other tweens of the same type to avoid a deadlock
		is_faceup = value
		# When we change faceup state, we reset the is_viewed to false
		if set_is_viewed(false) == CFConst.ReturnCode.FAILED:
			print("ERROR: Something went unexpectedly in set_is_faceup")
		if value:
			_flip_card($Control/Back, $Control/Front,instant)
			# We need this check, as this node might not be ready
			# Yet when a viewport focus dupe is instancing
			buttons.set_button_visible("View", false)
			card_back.stop_card_back_animation()
			# When we flip face up, we also want to show the dupe card
			# in the focus viewport
			# However we also need to protect this call from the dupe itself
			# calling it when it hasn't yet been added to its parent
			if cfc.NMAP.get("main", null) and get_parent():
				# we need to check if there's actually a viewport focus
				# card, as we may be flipping the card via code
				if len(cfc.NMAP.main._previously_focused_cards):
					# The currently active viewport focus is always in the
					# _previously_focused_cards list, as the last card
					var dupe_card = cfc.NMAP.main._previously_focused_cards.back()
					var dupe_front = dupe_card.get_node("Control/Front")
					var dupe_back = dupe_card.get_node("Control/Back")
					_flip_card(dupe_back, dupe_front, true)
		else:
			_flip_card($Control/Front, $Control/Back,instant)
			buttons.set_button_visible("View", true)
#			if get_parent() == cfc.NMAP.board:
			card_back.start_card_back_animation()
			# When we flip face down, we also want to hide the dupe card
			# in the focus viewport
			# However we also need to protect this call from the dupe itself
			# calling it when it hasn't yet been added to its parent
			if cfc.NMAP.get("main", null):
				# we need to check if there's actually a viewport focus
				# card, as we may be flipping the card via code
				if len(cfc.NMAP.main._previously_focused_cards):
					var dupe_card = cfc.NMAP.main._previously_focused_cards.back()
					var dupe_front = dupe_card.get_node("Control/Front")
					var dupe_back = dupe_card.get_node("Control/Back")
					_flip_card(dupe_front, dupe_back, true)
		retcode = CFConst.ReturnCode.CHANGED
		emit_signal("card_flipped", self, "card_flipped", {"is_faceup": value})
	# If we're doing a check, then we just report CHANGED.
	else:
		retcode = CFConst.ReturnCode.CHANGED
	return retcode


# Getter for is_faceup
func get_is_faceup() -> bool:
	return is_faceup


# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# * Returns CFConst.ReturnCode.CHANGED if the card actually changed view status
# * Returns CFConst.ReturnCode.OK if the card was already in the correct view status
# * Returns CFConst.ReturnCode.FAILED if changing the status is now allowed
func set_is_viewed(value: bool) -> int:
	var retcode: int
	if value == true:
		if is_faceup == true:
			# Players can already see faceup cards
			retcode = CFConst.ReturnCode.FAILED
		elif value == is_viewed:
			retcode = CFConst.ReturnCode.OK
		else:
			is_viewed = true
			if get_parent() != null and get_tree().get_root().has_node('Main'):
				var dupe_front = cfc.NMAP.main._previously_focused_cards.back()\
						.get_node("Control/Front")
				var dupe_back = cfc.NMAP.main._previously_focused_cards.back()\
						.get_node("Control/Back")
				_flip_card(dupe_back, dupe_front, true)
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = true
			retcode = CFConst.ReturnCode.CHANGED
			# We only emit a signal when we view the card
			# not when we unview it as that happens naturally
			emit_signal("card_viewed", self, "card_viewed",  {"is_viewed": true})
	else:
		if value == is_viewed:
			retcode = CFConst.ReturnCode.OK
		elif is_faceup == true:
			retcode = CFConst.ReturnCode.CHANGED
			is_viewed = false
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = false
		else:
			# We don't allow players to unview cards
			retcode = CFConst.ReturnCode.FAILED
	return retcode


# Getter for is_faceup
func get_is_viewed() -> bool:
	return is_viewed


# Setter for card_name
# Also changes the card label and the node name
func set_card_name(value : String) -> void:
	var name_label = $Control/Front/CardText/Name
	_set_label_text(name_label,value)
	name = value
	card_name = value
	properties["Name"] = value


# Getter for card_name
func get_card_name() -> String:
	return card_name


# Overwrites the built-in set name, so that it also sets card_name
#
# It's preferrable to set card_name instead.
func set_name(value : String) -> void:
	.set_name(value)
	$Control/Front/CardText/Name.text = value
	card_name = value

# Setter for card_rotation.
#
# Rotates the card the specified number of degrees.
#
# If the caller specifies the degree the card already has,
# and they have enabled the toggle flag,
# then we just reset the card to 0 degrees.
#
# * Returns CFConst.ReturnCode.CHANGED if the card actually changed rotation.
# * Returns CFConst.ReturnCode.OK if the card was already in the correct rotation.
# * Returns CFConst.ReturnCode.FAILED if an invalid rotation was specified.
func set_card_rotation(value: int, toggle := false, start_tween := true, check := false) -> int:
	var retcode
	# For cards we only allow orthogonal degrees of rotation
	# If it's not, we consider the request failed
	if not value in [0,90,180,270]:
		retcode = CFConst.ReturnCode.FAILED
	# We only allow rotating card while they're on the board
	elif value != 0 and get_parent() != cfc.NMAP.board:
		retcode = CFConst.ReturnCode.FAILED
	# If the card is already in the specified rotation
	# and a toggle was not requested, we consider we did nothing
	elif value == card_rotation and not toggle:
		retcode = CFConst.ReturnCode.OK
		# We add this check because hand oval rotation
		# does not change the card_rotation property
		# so we ensure that the displayed rotation of a card
		# which is not in hand, matches our expectations
		if get_parent() != cfc.NMAP.hand \
				and cfc.hand_use_oval_shape \
				and $Control.rect_rotation != 0.0 \
				and not $Tween.is_active():
			_add_tween_rotation($Control.rect_rotation,value)
			if start_tween:
				$Tween.start()
	else:
		# If the toggle was specified then if the card matches the requested
		# rotation, we reset it to 0 degrees
		if card_rotation == value and toggle:
			value = 0

		# We modify the card only if this is not a cost dry-run
		if not check:
			card_rotation = value
			# If the value is 0 but the card is in an oval hand, we ensure the actual
			# rotation we apply to the card will be their hand oval rotation
			if value == 0 \
					and get_parent() == cfc.NMAP.hand \
					and cfc.hand_use_oval_shape:
				value = int(_recalculate_rotation())
			$CollisionShape2D.rotation_degrees = value
			# We make sure to remove other tweens of the same type
			# to avoid a deadlock
			# There's no way to rotate the Area2D node,
			# so we just rotate the internal $Control. The results are the same.
			_add_tween_rotation($Control.rect_rotation,value)
			# We only start the animation if this flag is set to true
			# This allows us to set the card to rotate on the next
			# available tween, instead of immediately.
			if start_tween:
				$Tween.start()
			#$Control/Tokens.rotation_degrees = -value # need to figure this out
			# When the card actually changes orientation
			# We report that it changed.
			emit_signal("card_rotated", self, "card_rotated",  {"degrees": value})

		retcode = CFConst.ReturnCode.CHANGED
	return retcode


# Getter for card_rotation
func get_card_rotation() -> int:
	return card_rotation


# Arranges so that the card enters the chosen container.
#
# Will take care of interpolation.
#
# If the target container is the board, the card will either be placed at the
# mouse position, or at the 'boardPosition' variable.
#
# If placed in a pile, the index determines the card's position
# among other card. If it's -1, card will be placed on the bottom of the pile
func move_to(targetHost,
		index := -1,
		boardPosition := Vector2(-1,-1)) -> void:
#	if cfc.focus_style:
#		# We make to sure to clear the viewport focus because
#		# the mouse exited signal will not fire after drag&drop in a container
#		cfc.NMAP.main.unfocus()
	# We need to store the parent, because we won't be able to know it later
	var parentHost = get_parent()
	# We want to keep the token drawer closed during movement
	tokens.is_drawer_open = false
	if CFConst.DISABLE_BOARD_DROP and targetHost == cfc.NMAP.board:
		targetHost = parentHost
	if targetHost != parentHost:
		# When changing parent, it resets the position of the child it seems
		# So we store it to know where the card used to be, before moving it
		var previous_pos = global_position
		var global_pos = global_position
		# We need to remove the current parent node before adding a different one
		parentHost.remove_child(self)
		targetHost.add_child(self)
		# The below is used when a specific card position is requested
		# It converts the requested card position, to absolute node position
		# between all nodes
		if index >= 0:
			targetHost.move_child(self,
					targetHost.translate_card_index_to_node_index(index))
		# Ensure card stays where it was before it changed parents
		global_position = previous_pos
		if targetHost.is_in_group("hands"):
#			_tween_interpolate_visibility(1,0.3)
			# We need to adjust the start position based on the global position
			# coordinates as they would be inside the hand control node
			# So we transform global coordinates to hand rect coordinates.
			previous_pos = targetHost.to_local(global_pos)
			# The end position is always the final position the card would be
			# inside the hand
			_target_position = recalculate_position()
			card_rotation = 0
			_target_rotation = _recalculate_rotation()
			state = CardState.MOVING_TO_CONTAINER
			emit_signal("card_moved_to_hand",
					self,
					"card_moved_to_hand",
					 {"destination": targetHost, "source": parentHost})
			# We reorganize the left over cards in hand.
			for c in targetHost.get_all_cards():
				if c != self:
					c.interruptTweening()
					c.reorganize_self()
			if set_is_faceup(true) == CFConst.ReturnCode.FAILED:
				print("ERROR: Something went unexpectedly in set_is_faceup")
		elif targetHost.is_in_group("piles"):
			# The below checks if the pile we're moving is in a popup
			# If the card is also in a popup of the same pile
			# we assume we're moving back
			# to the same container, so we do nothing
			# The finite state machine  will reset the card to its position
			if "CardPopUpSlot" in parentHost.name \
					and parentHost.get_parent().get_parent().get_parent() == targetHost:
				if targetHost.get_node("ViewPopup").visible == true:
					pass
			else:
				# Added because sometimes it ended up stuck and a card remained
				# visible on top of deck
				$Tween.remove_all()
				# We need to adjust the end position based on the local rect inside
				# the container control node
				# So we transform global coordinates to container rect coordinates.
				previous_pos = targetHost.to_local(global_pos)
				# The target position is always the local coordinates
				# of the stack position the card would have
				# (this means how far up in the pile the card would appear)
				_target_position = targetHost.get_stack_position(self)
				_target_rotation = 0.0
				state = CardState.MOVING_TO_CONTAINER
				emit_signal("card_moved_to_pile",
						self,
						"card_moved_to_pile",
						{"destination": targetHost, "source": parentHost})
				if set_is_faceup(targetHost.faceup_cards) == CFConst.ReturnCode.FAILED:
					print("ERROR: Something went unexpectedly in set_is_faceup")
				# If we have fancy movement, we need to wait for 2 tweens to finish
				# before we reorganize the stack.
				# One for the fancy move, and then the move to the final position.
				# If we don't then the card will appear to teleport
				# to the pile before starting animation
				yield($Tween, "tween_all_completed")
				if cfc.fancy_movement:
					yield($Tween, "tween_all_completed")
				targetHost.reorganize_stack()
		else:
			interruptTweening()
			_target_rotation = _recalculate_rotation()
			if len(_potential_cards):
				# The _potential_cards are always organized so that the card higher
				# in index that we were hovering over, is the last in the array.
				attach_to_host(_potential_cards.back())
			else:
				# The developer is allowed to pass a position override to the
				# card placement
				if boardPosition == Vector2(-1,-1):
					_determine_target_position_from_mouse()
				else:
					_target_position = boardPosition
				raise()
			state = CardState.DROPPING_TO_BOARD
			emit_signal("card_moved_to_board",
					self,
					"card_moved_to_board",
					{"destination": targetHost, "source": parentHost})
		if parentHost and parentHost.is_in_group("hands"):
			# We also want to rearrange the hand when we take cards out of it
			for c in parentHost.get_all_cards():
				# But this time we don't want to rearrange ourselves, as we're
				# in a different container by now
				if c != self and c.state != CardState.DRAGGED:
					c.interruptTweening()
					c.reorganize_self()
		elif parentHost and parentHost == cfc.NMAP.board:
			# If the card was or had attachments and it is removed from the table,
			# all attachments status is cleared
			_clear_attachment_status()
			# If the card has tokens, and tokens_only_on_board is true
			# we remove all tokens
			# (The cfc._ut_tokens_only_on_board is there for unit testing)
			if CFConst.TOKENS_ONLY_ON_BOARD or cfc._ut_tokens_only_on_board:
				for token in tokens.get_all_tokens().values():
					token.queue_free()
	else:
		# Here we check what to do if the player just moved the card back
		# to the same container
		if parentHost == cfc.NMAP.hand:
			state = CardState.IN_HAND
			reorganize_self()
		elif parentHost == cfc.NMAP.board:
			# Checking if this is an attachment and we're looking for a new host
			if len(_potential_cards):
				attach_to_host(_potential_cards.back())
			# If we are an attachment and were moved elsewhere
			# We reset the position.
			elif current_host_card:
				var attach_index = current_host_card.attachments.find(self)
				_target_position = (current_host_card.global_position
						+ Vector2(0,(attach_index + 1)
						* $Control.rect_size.y
						* CFConst.ATTACHMENT_OFFSET))
			else:
				_determine_target_position_from_mouse()
				raise()
			state = CardState.ON_PLAY_BOARD
		elif "CardPopUpSlot" in parentHost.name:
			state = CardState.IN_POPUP
	# Just in case there's any leftover potential host highlights
	if len(_potential_cards):
		for card in _potential_cards:
			card.highlight.set_highlight(false)
		_potential_cards.clear()


# Executes the tasks defined in the card's scripts in order.
#
# Returns a [ScriptingEngine] object but that it not statically typed
# As it causes the parser think there's a cyclic dependency.
func execute_scripts(
		trigger_card: Card = self,
		trigger: String = "manual",
		signal_details: Dictionary = {}):
	var card_scripts
	var sceng = null
	# If scripts have been defined directly in this Card object
	# They take precedence over CardScriptDefinitions.gd
	#
	# This allows us to modify a card's scripts during runtime
	# in isolation from other cards of the same name
	if not scripts.empty():
		card_scripts = scripts.get(trigger,{}).duplicate()
	else:
		# This retrieves all the script from the card, stored in cfc
		# The seeks in them the specific trigger we're using in this
		# execution
		card_scripts = cfc.set_scripts.get(card_name,{}).get(trigger,{})

	# I use this spot to add a breakpoint when testing script behaviour
	# especially on filters
	if _debugger_hook:
		pass

	# We check the trigger against the filter defined
	# If it does not match, then we don't pass any scripts for this trigger.
	if not SP.filter_trigger(
			card_scripts,
			trigger_card,
			self,
			signal_details):
		card_scripts.clear()
	var state_scripts = []
	# We select which scripts to run from the card, based on it state
	var state_exec := "NONE"
	match state:
		CardState.ON_PLAY_BOARD, CardState.FOCUSED_ON_BOARD:
			# We assume only faceup cards can execute scripts on the board
			if is_faceup:
				state_exec ="board"
		CardState.IN_HAND, CardState.FOCUSED_IN_HAND, CardState.PUSHED_ASIDE:
				state_exec ="hand"
		CardState.IN_POPUP, CardState.FOCUSED_IN_POPUP:
				state_exec ="pile"
	state_scripts = card_scripts.get(state_exec, [])
	# Here we check for confirmation of optional trigger effects
	# There should be an SP.KEY_IS_OPTIONAL definition per state
	# E.g. if board scripts are optional, but hand scripts are not
	# Then you'd include an "is_optional_board" key at the same level as "board"
	var confirm_return = CFUtils.confirm(
		card_scripts,
		card_name,
		trigger,
		state_exec)
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
		# If the player chooses not to play an optional cost
		# We consider the whole cost dry run unsuccesful
		if not confirm_return:
			state_scripts = []

	# If the state_scripts return a dictionary entry
	# it means it's a multiple choice between two scripts
	if typeof(state_scripts) == TYPE_DICTIONARY:
		var choices_menu = _CARD_CHOICES_SCENE.instance()
		choices_menu.prep(self.card_name,state_scripts)
		# We have to wait until the player has finished selecting an option
		yield(choices_menu,"id_pressed")
		# If the player just closed the pop-up without choosing
		# an option, we don't execute anything
		if choices_menu.id_selected:
			state_scripts = state_scripts[choices_menu.selected_key]
		else: state_scripts = []
		# Garbage cleanup
		choices_menu.queue_free()

	# To avoid unnecessary operations
	# we evoce the ScriptingEngine only if we have something to execute
	if len(state_scripts):
		# This evocation of the ScriptingEngine, checks the card for
		# cost-defined tasks, and performs a dry-run on them
		# to ascertain whether they can all be paid,
		# before executing the card script.
		sceng = scripting_engine.new(
				self,
				state_scripts,
				true)
		# In case the script involves targetting, we need to wait on further
		# execution until targetting has completed
		if not sceng.all_tasks_completed:
			yield(sceng,"tasks_completed")
		# If the dry-run of the ScriptingEngine returns that all
		# costs can be paid, then we proceed with the actual run
		if sceng.can_all_costs_be_paid:
			#print("DEBUG:" + str(state_scripts))
			# The ScriptingEngine is where we execute the scripts
			# We cannot use its class reference,
			# as it causes a cyclic reference error when parsing
			sceng = scripting_engine.new(
					self,
					state_scripts)
	return(sceng)


# Handles the card becoming an attachment for a specified host Card object
func attach_to_host(host: Card, is_following_previous_host = false) -> void:
	# First we check if the selected host is not the current host anyway.
	# If it is, we do nothing else
	if host != current_host_card:
		# If the card is not yet on the board, we move it there
		if get_parent() != cfc.NMAP.board:
			move_to(cfc.NMAP.board, -1, host.position)
		# If we already had a host, we clear our state with it
		# I don't know why, but logic breaks if I don't use the is_following_previous_host flag
		# It should work without it, but it doesn't
		# The is_following_previous_host var signifies that this card
		# is being attached to this host, because its previous host
		# also became an attachment here.
		if current_host_card and not is_following_previous_host:
			current_host_card.attachments.erase(self)
			emit_signal("card_unattached",
					self,
					"card_unattached",
					{"host": current_host_card})
		current_host_card = host
		# Once we selected the host, we don't need anything in the array anymore
		_potential_cards.clear()
		# We also clear the highlights on our new host
		current_host_card.highlight.set_highlight(false)
		# We set outselves as an attachment on the target host for easy iteration
		current_host_card.attachments.append(self)
		#print(current_host_card.attachments)
		# We make existing attachments reattach to the new host directly
		# Otherwise it becomes too complex to handle attachment indexes
		for card in attachments:
			card.attach_to_host(host,true)
		attachments.clear()
		# The position below the host is based on how many other attachments it has
		# We offset our position below the host based on a percentage of
		# the card size, times the index among other attachments
		var attach_index = current_host_card.attachments.find(self)
		_target_position = (current_host_card.global_position
				+ Vector2(0,(attach_index + 1)
				* $Control.rect_size.y
				* CFConst.ATTACHMENT_OFFSET))
		emit_signal("card_attached",
				self,
				"card_attached",
				{"host": host})


# Overrides the built-in get_class to
# Returns "Card" instead of "Area2D"
func get_class(): return "Card"


# Ensures the card is placed in the right position in the hand
# In relation to the other cards in the hand
#
# It will also adjust the separation between cards depending on the amount
# of cards in-hand
func reorganize_self() ->void:
	# We clear the card as being in-focus if we're asking it to be reorganized
	_focus_completed = false
	match state:
		CardState.IN_HAND, CardState.FOCUSED_IN_HAND, CardState.PUSHED_ASIDE:
			_target_position = recalculate_position()
			_target_rotation = _recalculate_rotation()
			state = CardState.REORGANIZING
	# This second match is  to prevent from changing the state
	# when we're doing fancy movement
	# and we're still in the first part (which is waiting on an animation yield).
	# Instead, we just change the target position transparently,
	# and when the second part of the animation begins
	# it will automatically pick up the right location.
	match state:
		CardState.MOVING_TO_CONTAINER:
			_target_position = recalculate_position()
			_target_rotation = _recalculate_rotation()


# Stops existing card animations then makes sure they're
# properly cleaned-up to allow future animations to play.
func interruptTweening() ->void:
	# This if-logic is there to avoid interrupting animations during fancy_movement,
	# as we want the first part to play always
	# Effectively we're saying if fancy movement is turned on, and you're
	# still doing the first part, don't interrupt
	# If you've finished the first part and are not still in the
	# move to another container movement, then you can interrupt.
	if not cfc.fancy_movement or (cfc.fancy_movement
			and (_fancy_move_second_part
			or state != CardState.MOVING_TO_CONTAINER)):
		$Tween.remove_all()
		state = CardState.IN_HAND


# Changes card focus (highlighted and put on the focus viewport)
func set_focus(requestedFocus: bool) -> void:
	 # We use an if to avoid performing constant operations in _process
	if highlight.visible != requestedFocus and \
			highlight.modulate == CFConst.FOCUS_HOVER_COLOUR:
		highlight.visible = requestedFocus
	if cfc.focus_style: # value 0 means only scaling focus
		if requestedFocus:
			cfc.NMAP.main.focus_card(self)
		else:
			cfc.NMAP.main.unfocus(self)
	# Tokens drawer is an optional node, so we check if it exists
	# We also generally only have tokens on the table
	if $Control.has_node("Tokens") \
			and state in [CardState.ON_PLAY_BOARD, CardState.FOCUSED_ON_BOARD]:
		tokens.is_drawer_open = requestedFocus
#		if name == "Card" and get_parent() == cfc.NMAP.board:
#			print(requestedFocus)


# Tells us the focus-state of a card
#
# Returns true if card is currently in focus, else false
func get_focus() -> bool:
	var focusState = false
	match state:
		CardState.FOCUSED_IN_HAND, CardState.FOCUSED_ON_BOARD:
			focusState = true
	return(focusState)


# Returns the Card's index position among other card objects
func get_my_card_index() -> int:
	if "CardPopUpSlot" in get_parent().name:
		return(0)
	else:
		return get_parent().get_card_index(self)


# Changes the hosted Control nodes filters
#
# * When set to false, card cannot receive inputs anymore
#    (this is useful when card is in motion or in a pile)
# * When set to true, card can receive inputs again
func set_control_mouse_filters(value = true) -> void:
	var control_filter := 0
	if not value:
		control_filter = 2
	# We do a comparison first, to make sure we avoid unnecessary operations
	if $Control.mouse_filter != control_filter:
		$Control.mouse_filter = control_filter
	if monitorable != value:
		monitorable = value


# Get card position in hand by index
# if use oval shape, the card has a certain offset according to the angle
func recalculate_position(index_diff = null) -> Vector2:
	if cfc.hand_use_oval_shape:
		return _recalculate_position_use_oval(index_diff)
	return _recalculate_position_use_rectangle(index_diff)


# Animates a card semi-randomly to make it looks like it's being shuffled
# Then it returns it to its original location
func animate_shuffle(anim_speed : float, style : int) -> void:
	var starting_card_position = position
	var csize : Vector2
	var random_x : float
	var random_y : float
	var random_rot : float
	var center_card_pop_position = starting_card_position+Vector2(random_x,random_y)
	var start_pos_anim
	var end_pos_anim
	var rot_anim
	var pos_speed := anim_speed
	var rot_speed := anim_speed
	if style == CFConst.ShuffleStyle.CORGI:
		csize = $Control.rect_size * 0.65
		random_x = CFUtils.randf_range(- csize.x, csize.x)
		random_y = CFUtils.randf_range(- csize.y, csize.y)
		random_rot = CFUtils.randf_range(-20, 20)
		center_card_pop_position = starting_card_position \
				+ Vector2(random_x, random_y)
		start_pos_anim = Tween.TRANS_CIRC
		end_pos_anim = Tween.TRANS_CIRC
		rot_anim = Tween.TRANS_CIRC
	# 2 is splash
	elif style == CFConst.ShuffleStyle.SPLASH:
		csize = $Control.rect_size * 0.85
		random_x = CFUtils.randf_range(- csize.x, csize.x)
		random_y = CFUtils.randf_range(- csize.y, csize.y)
		random_rot = CFUtils.randf_range(-180, 180)
		center_card_pop_position = starting_card_position \
				+ Vector2(random_x, random_y)
		start_pos_anim = Tween.TRANS_ELASTIC
		end_pos_anim = Tween.TRANS_QUAD
		rot_anim = Tween.TRANS_CIRC
		pos_speed = pos_speed
	elif style == CFConst.ShuffleStyle.SNAP:
		csize = $Control.rect_size
		center_card_pop_position.y = starting_card_position.y \
				+ $Control.rect_size.y
		start_pos_anim = Tween.TRANS_ELASTIC
		end_pos_anim = Tween.TRANS_ELASTIC
		rot_anim = null
		pos_speed = pos_speed
	elif style == CFConst.ShuffleStyle.OVERHAND:
		csize = $Control.rect_size * 1.1
		random_x = CFUtils.randf_range(- csize.x/10, csize.x/10)
		random_y = CFUtils.randf_range(- csize.y, - csize.y/2)
		random_rot = CFUtils.randf_range(-10, 10)
		center_card_pop_position = starting_card_position \
				+ Vector2(random_x,random_y)
		start_pos_anim = Tween.TRANS_CIRC
		end_pos_anim = Tween.TRANS_SINE
		rot_anim = Tween.TRANS_ELASTIC
	_add_tween_position(starting_card_position,center_card_pop_position,
			pos_speed,start_pos_anim,Tween.EASE_OUT)
	if rot_anim:
		_add_tween_rotation(0,random_rot,rot_speed,rot_anim,Tween.EASE_OUT)
	_tween.start()
	yield(_tween, "tween_all_completed")
	_add_tween_position(center_card_pop_position,starting_card_position,
			pos_speed,end_pos_anim,Tween.EASE_IN)
	if rot_anim:
		_add_tween_rotation(random_rot,0,rot_speed,rot_anim,Tween.EASE_IN)
	_tween.start()


# Makes attachments always move with their parent around the board
func _organize_attachments() -> void:
	# We only do this if the parent is still on the board
	if get_parent() == cfc.NMAP.board:
		for card in attachments:
			# We use the index of the attachment among other attachments
			# to figure out its index and placement
			var attach_index = attachments.find(card)
			if attach_index:
				# if the card is not the first attachment to this host
				# Then we make sure that each subsequent card is higher
				# in the node hierarchy than its parent
				# This will make latter cards draw below the others
				if card.get_index() > attachments[attach_index - 1].get_index():
					get_parent().move_child(card,
							attachments[attach_index - 1].get_index())
			# If the card if the first for its host, we need to make sure
			# it is higher in the hierarchy than the host
			elif card.get_index() > self.get_index():
				get_parent().move_child(card,self.get_index())
			# We don't want to try and move it if it's still tweening.
			# But if it isn't, we make sure it always follows its parent
			if not card.get_node('Tween').is_active() and \
					card.state in \
					[CardState.ON_PLAY_BOARD,CardState.FOCUSED_ON_BOARD]:
				card.global_position = global_position + \
						Vector2(0,(attach_index + 1) \
						* $Control.rect_size.y \
						* CFConst.ATTACHMENT_OFFSET)


# Returns the global mouse position but ensures it does not exit the
# viewport limits when including the card rect
#
# Returns the adjusted global_mouse_position
func _determine_board_position_from_mouse() -> Vector2:
	var targetpos: Vector2 = cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos()
	if targetpos.x + $Control.rect_size.x * scale.x >= get_viewport().size.x:
		targetpos.x = get_viewport().size.x - $Control.rect_size.x * scale.x
	if targetpos.x < 0:
		targetpos.x = 0
	if targetpos.y + $Control.rect_size.y * scale.y >= get_viewport().size.y:
		targetpos.y = get_viewport().size.y - $Control.rect_size.y * scale.y
	if targetpos.y < 0:
		targetpos.y = 0
	return targetpos


# This function figures out where on the table a card should be placed
# based on the mouse position
# It takes extra care not to drop the card outside viewport margins
func _determine_target_position_from_mouse() -> void:
	_target_position = _determine_board_position_from_mouse()
	# The below ensures the card doesn't leave the viewport dimentions
	if _target_position.x + $Control.rect_size.x * CFConst.PLAY_AREA_SCALE.x \
			> get_viewport().size.x:
		_target_position.x = get_viewport().size.x \
				- $Control.rect_size.x \
				* CFConst.PLAY_AREA_SCALE.x
	if _target_position.y + $Control.rect_size.y * CFConst.PLAY_AREA_SCALE.y \
			> get_viewport().size.y:
		_target_position.y = get_viewport().size.y \
				- $Control.rect_size.y \
				* CFConst.PLAY_AREA_SCALE.y


# Instructs the card to move aside for another card enterring focus
func _pushAside(targetpos: Vector2, target_rotation: float) -> void:
	interruptTweening()
	_target_position = targetpos
	_target_rotation = target_rotation
	state = CardState.PUSHED_ASIDE


# Pick up a card to drag around with the mouse.
func _start_dragging() -> void:
	# When dragging we want the dragged card to always be drawn above all else
	z_index = 99
	# We have use parent viewport to calculate global_position
	# due to godotengine/godot#30215
	# This is caused because we're using a viewport node and scaling the game
	# in full-creen.
	if not cfc.ut:
		if ProjectSettings.get("display/window/stretch/mode") != 'disabled':
			get_tree().current_scene.get_viewport().warp_mouse(global_position + Vector2(5,5))
		# However the above messes things if we don't have stretch mode,
		# so we ignore it then
		else:
			get_viewport().warp_mouse(global_position)
	state = CardState.DRAGGED
	# We check if the card was already overlapping with other card
	# before we started dragging. If so, we activate the code
	# which checks for potential hosts, on all these cards to make sure
	# we don't miss any.
	for obj in get_overlapping_areas():
		_on_Card_area_entered(obj)
	if get_parent().is_in_group("hands"):
		# While we're dragging the card from hand, we want the other cards
		# to move to their expected position in hand
		for c in get_parent().get_all_cards():
			if c != self:
				c.interruptTweening()
				c.reorganize_self()


# Determines the state a card should have,
# based on the card's container grouping.
#
# This is needed because some states are generic
# and don't always know the state the card should be afterwards
func _determine_idle_state() -> void:
	if get_parent().is_in_group("hands"):
		state = CardState.IN_HAND
	# The extra if is in case the ViewPopup is currently active when the card
	# is being moved into the container
	elif get_parent().is_in_group("piles"):
		state = CardState.IN_PILE
	elif "CardPopUpSlot" in get_parent().name:
		state = CardState.IN_POPUP
	else:
		state = CardState.ON_PLAY_BOARD


# Makes the card change visibility nicely
func _tween_interpolate_visibility(visibility: float, time: float) -> void:
	# We only want to do something if we're actually doing something
	if modulate[3] != visibility:
		$Tween.interpolate_property(self,'modulate',
				modulate, Color(1, 1, 1, visibility), time,
				Tween.TRANS_QUAD, Tween.EASE_OUT)


# Clears all attachment/hosting status.
# It is typically called when a card is removed from the table
func _clear_attachment_status() -> void:
	if current_host_card:
		emit_signal("card_unattached",
				self,
				"card_unattached",
				{"host": current_host_card})
		current_host_card.attachments.erase(self)
		current_host_card = null
	for card in attachments:
		card.current_host_card = null
		# Attachments typically follow their parents to the same container
		card.move_to(get_parent())
		# We do a small wait to make the attachment drag look nicer
		yield(get_tree().create_timer(0.1), "timeout")
	attachments.clear()


# Detects when the mouse is still hovering over the card
#
# We need to detect this extra, for the same reasons as the targetting buttons
# In case the mouse was hovering over the tokens area and just exited
#
# Returns true if the mouse is hovering over the card, else false
func _is_card_hovered() -> bool:
	var ret = false
#	if (cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos().x
#			>= $Control.rect_global_position.x and
#			cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos().y
#			>= $Control.rect_global_position.y and
#			cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos().x
#			<= $Control.rect_global_position.x
#			+ $Control.rect_size.x and
#			cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos().y
#			<= $Control.rect_global_position.y
#			+ $Control.rect_size.y):
	if cfc.NMAP.board.mouse_pointer in get_overlapping_areas():
		ret = true
	#print(ret)
	return(ret)


# Flips the visible parts of the card control nodes
# so that the correct Panel (Card Back or Card Front) and children is visible
#
# It also pretends to flip the highlight, otherwise it looks fake.
func _flip_card(to_invisible: Control, to_visible: Control, instant := false) -> void:
	if instant:
		to_visible.visible = true
		to_visible.rect_scale.x = 1
		to_visible.rect_position.x = 0
		to_invisible.visible = false
		to_invisible.rect_scale.x = 0
		to_invisible.rect_position.x = to_visible.rect_size.x/2
	# When dupe cards in focus viewport are created, they have parent == null
	# This causes them to raise an error trying to create a tween
	# So we skip that.
	elif get_parent() == null:
		pass
	else:
		# We clear existing tweens to avoid a deadlocks
		for n in [$Control/Front, $Control/Back, highlight]:
			_flip_tween.remove(n,'rect_scale')
			_flip_tween.remove(n,'rect_position')
		_flip_tween.interpolate_property(to_invisible,'rect_scale',
				to_invisible.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		_flip_tween.interpolate_property(to_invisible,'rect_position',
				to_invisible.rect_position, Vector2(
				to_invisible.rect_size.x/2,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		_flip_tween.interpolate_property(highlight,'rect_scale',
				highlight.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		# The highlight is larger than the card size, but also offet a big
		# so that it's still centered. This way its borders only extend
		# over the card borders. We need to offest to the right location.
		_flip_tween.interpolate_property(highlight,'rect_position',
				highlight.rect_position, Vector2(
				(highlight.rect_size.x-3)/2,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		_flip_tween.start()
		yield(_flip_tween, "tween_all_completed")
		to_visible.visible = true
		to_invisible.visible = false
		_flip_tween.interpolate_property(to_visible,'rect_scale',
				to_visible.rect_scale, Vector2(1,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.interpolate_property(to_visible,'rect_position',
				to_visible.rect_position, Vector2(0,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.interpolate_property(highlight,'rect_scale',
				highlight.rect_scale, Vector2(1,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.interpolate_property(highlight,'rect_position',
				highlight.rect_position, Vector2(-3,-3), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.start()


# Card rotation animation
func _add_tween_rotation(
		expected_rotation: float,
		target_rotation: float,
		runtime := 0.3,
		trans_type = Tween.TRANS_BACK,
		ease_type = Tween.EASE_IN_OUT):
	$Tween.remove($Control,'rect_rotation')
	$Tween.interpolate_property($Control,'rect_rotation',
			expected_rotation, target_rotation, runtime,
			trans_type, ease_type)
	# We ensure the card_rotation value is also kept up to date
	# But onlf it it's one of the expected multiples
	if int(target_rotation) != card_rotation \
			and int(target_rotation) in [0,90,180,270]:
		card_rotation = int(target_rotation)


# Card position animation
func _add_tween_position(
		expected_position: Vector2,
		target_position: Vector2,
		runtime := 0.3,
		trans_type = Tween.TRANS_CUBIC,
		ease_type = Tween.EASE_OUT):
	$Tween.remove(self,'position')
	$Tween.interpolate_property(self,'position',
			expected_position, target_position, runtime,
			trans_type, ease_type)


# Card global position animation
func _add_tween_global_position(
		expected_position: Vector2,
		target_position: Vector2,
		runtime := 0.5,
		trans_type = Tween.TRANS_BACK,
		ease_type = Tween.EASE_IN_OUT):
	$Tween.remove(self,'global_position')
	$Tween.interpolate_property(self,'global_position',
			expected_position, target_position, runtime,
			trans_type, ease_type)


# Card scale animation
func _add_tween_scale(
		expected_scale: Vector2,
		target_scale: Vector2,
		runtime := 0.3,
		trans_type = Tween.TRANS_CUBIC,
		ease_type = Tween.EASE_OUT):
	$Tween.remove(self,'scale')
	$Tween.interpolate_property(self,'scale',
			expected_scale, target_scale, runtime,
			trans_type, ease_type)


# A rudimentary Finite State Engine for cards.
#
# Makes sure that when a card is in a specific state while
# its position, highlights, scaling and so on, stay as expected
func _process_card_state() -> void:
	match state:
		CardState.IN_HAND:
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			# warning-ignore:return_value_discarded
			# When we have an oval shape, we ensure the cards stay
			# in the rotation expected of their position
			if cfc.hand_use_oval_shape:
				_target_rotation  = _recalculate_rotation()
				if not $Tween.is_active() \
						and $Control.rect_rotation != _target_rotation:
					_add_tween_rotation($Control.rect_rotation,_target_rotation)
					$Tween.start()

		CardState.FOCUSED_IN_HAND:
			# Used when card is focused on by the mouse hovering over it.
			# We increase the z_index to allow the focused card appear
			# always over its neighbours
			z_index = 1
			set_focus(true)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0,false,false)
			if not $Tween.is_active() and \
					not _focus_completed and \
					cfc.focus_style != CFConst.FocusStyle.VIEWPORT:
				var expected_position: Vector2 = recalculate_position()
				var expected_rotation: float = _recalculate_rotation()
				# We figure out our neighbours by their index
				var neighbours := []
				for neighbour_index_diff in [-2,-1,1,2]:
					var hand_size: int = get_parent().get_card_count()
					var neighbour_index: int = \
							get_my_card_index() + neighbour_index_diff
					if neighbour_index >= 0 and neighbour_index <= hand_size - 1:
						var neighbour_card: Card = get_parent().get_card(neighbour_index)
						# Neighbouring cards are pushed to the side to allow
						# the focused card to not be overlapped
						# The amount they're pushed is relevant to
						# how close neighbours they are.
						# Closest neighbours (1 card away) are pushed more
						# than further neighbours.
						neighbour_card._pushAside(
								neighbour_card.recalculate_position(
									neighbour_index_diff),
								neighbour_card._recalculate_rotation(
									neighbour_index_diff))
						neighbours.append(neighbour_card)
				for c in get_parent().get_all_cards():
					if not c in neighbours and c != self:
						c.interruptTweening()
						c.reorganize_self()
				# When zooming in, we also want to move the card higher,
				# so that it's not under the screen's bottom edge.
				# We multiple with 0.25 to offset the increase in size
				# due to the 1.5 scale coming later.
				var oval_offset = 0.0
				# The below calculation ensures that rotated cards
				# Don't raise too much over the hand location, causing the card
				# focus to spazz-out.
				# This needs to be improved, as the multiplier needs to be
				# based on the angle somehow.
				if cfc.hand_use_oval_shape:
					oval_offset = (90 - abs(_recalculate_rotation())) * 0.75
				_target_position = expected_position \
						- Vector2($Control.rect_size.x \
						* 0.25,$Control.rect_size.y \
						* 0.5 + cfc.NMAP.hand.bottom_margin \
						- oval_offset)
				_target_rotation = expected_rotation
				# We make sure to remove other tweens of the same type
				# to avoid a deadlock
				_add_tween_position(expected_position, _target_position, 0.3)
				_add_tween_scale(scale, Vector2(1.5,1.5))

				if cfc.hand_use_oval_shape:
					_add_tween_rotation($Control.rect_rotation,0)
				else:
					# warning-ignore:return_value_discarded
					set_card_rotation(0)
				$Tween.start()
				_focus_completed = true
				# We don't change state yet, only when the focus is removed
				# from this card

		CardState.MOVING_TO_CONTAINER:
			# Used when moving card between places
			# (i.e. deck to hand, hand to discard etc)
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(false)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			# set_card_rotation(0,false,false)
			if not $Tween.is_active():
				var intermediate_position: Vector2
				if not scale.is_equal_approx(Vector2(1,1)):
					_add_tween_scale(scale, Vector2(1,1),0.4)
				if cfc.fancy_movement:
					# The below calculations figure out
					# the intermediate position as a spot,
					# offset towards the viewport center by an amount proportional
					# to distance from the viewport center.
					# (My math is not the best so there's probably a more elegant formula)
					var direction_x: int = -1
					var direction_y: int = -1
					if get_parent() != cfc.NMAP.board:
						# We determine its center position on the viewport
						var controlNode_center_position := \
								Vector2(global_position + $Control.rect_size/2)
						# We then direct this position towards the viewport center
						# If we are to the left/top of viewport center,
						# we offset towards the right/bottom (+offset)
						# If we are to the right/bottom of viewport center,
						# we offset towards the left/top (-offset)
						if controlNode_center_position.x < get_viewport().size.x/2:
							direction_x = 1
						if controlNode_center_position.y < get_viewport().size.y/2:
							direction_y = 1
						# The offset amount if calculated by creating a multiplier
						# based on the distance of our target container
						# from the viewport center
						# The further away they are, the more the intermediate point
						# moves towards the screen center
						# We always offset by percentages of the card size to
						# be consistent in case the card size changes
						var offset_x = (abs(controlNode_center_position.x
								- get_viewport().size.x/2)) / 250 * $Control.rect_size.x
						var offset_y = (abs(controlNode_center_position.y
								- get_viewport().size.y/2)) / 250 * $Control.rect_size.y
						var inter_x = controlNode_center_position.x \
								+ direction_x * offset_x
						var inter_y = controlNode_center_position.y \
								+ direction_y * offset_y
						# We calculate the position we want the card to move
						# on the viewport
						# then we translate that position to the local coordinates
						# within the parent control node
						#intermediate_position = Vector2(inter_x,inter_y)
						intermediate_position = Vector2(inter_x,inter_y)
					# The board doesn't have a node2d host container.
					# Instead we use directly the viewport coords.
					else:
						intermediate_position = get_viewport().size/2
					_add_tween_global_position(global_position, intermediate_position)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					_tween_stuck_time = 0
					_fancy_move_second_part = true
				# We need to check again, just in case it's been reorganized instead.
				if state == CardState.MOVING_TO_CONTAINER:
					_add_tween_position(position, _target_position, 0.35,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
					_add_tween_rotation($Control.rect_rotation,_target_rotation)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					_determine_idle_state()
				_fancy_move_second_part = false

		CardState.REORGANIZING:
			# Used when reorganizing the cards in the hand
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0,false,false)
			if not $Tween.is_active():
				$Tween.remove(self,'position') #
				_add_tween_position(position, _target_position, 0.4)
				if not scale.is_equal_approx(Vector2(1,1)):
					_add_tween_scale(scale, Vector2(1,1),0.4)
				_add_tween_rotation($Control.rect_rotation,_target_rotation, 0.4)
				$Tween.start()
				state = CardState.IN_HAND

		CardState.PUSHED_ASIDE:
			# Used when card is being pushed aside due to the focusing of a neighbour.
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			if not $Tween.is_active() and \
					not position.is_equal_approx(_target_position):
				_add_tween_position(position, _target_position, 0.3,
						Tween.TRANS_QUART, Tween.EASE_IN)
				_add_tween_rotation($Control.rect_rotation, _target_rotation, 0.3)
				if not scale.is_equal_approx(Vector2(1,1)):
					_add_tween_scale(scale, Vector2(1,1), 0.3,Tween.TRANS_QUART, Tween.EASE_IN)
				$Tween.start()
				# We don't change state yet,
				# only when the focus is removed from the neighbour

		CardState.DRAGGED:
			# Used when the card is dragged around the game with the mouse
			set_focus(true)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			if (not $Tween.is_active() and
				not scale.is_equal_approx(CFConst.CARD_SCALE_WHILE_DRAGGING) and
				get_parent() != cfc.NMAP.board):
				_add_tween_scale(scale, CFConst.CARD_SCALE_WHILE_DRAGGING, 0.2,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Tween.start()
			# We need to capture the mouse cursos in the window while dragging
			# because if the player drags the cursor outside the window and unclicks
			# The control will not receive the mouse input
			# and this will stay dragging forever
			if not cfc.ut:
				Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			$Control.set_default_cursor_shape(Input.CURSOR_CROSS)
			# We set the card to be centered on the mouse cursor to allow
			# the player to properly understand where it will go once dropped.
			global_position = _determine_board_position_from_mouse() - Vector2(5,5)
			_organize_attachments()
			# We want to keep the token drawer closed during movement
			tokens.is_drawer_open = false

		CardState.ON_PLAY_BOARD:
			# Used when the card is idle on the board
			set_focus(false)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			if not $Tween.is_active() and \
					not scale.is_equal_approx(CFConst.PLAY_AREA_SCALE):
				_add_tween_scale(scale, CFConst.PLAY_AREA_SCALE, 0.3,
						Tween.TRANS_SINE, Tween.EASE_OUT)
				$Tween.start()
			_organize_attachments()

		CardState.DROPPING_TO_BOARD:
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# Used when dropping the cards to the table
			# When dragging the card, the card is slightly behind the mouse cursor
			# so we tween it to the right location
			if not $Tween.is_active():
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
#				_target_position = _determine_board_position_from_mouse()
#				# The below ensures the card doesn't leave the viewport dimentions
#				if _target_position.x + $Control.rect_size.x * CFConst.PLAY_AREA_SCALE.x > get_viewport().size.x:
#					_target_position.x = get_viewport().size.x - $Control.rect_size.x * CFConst.PLAY_AREA_SCALE.x
#				if _target_position.y + $Control.rect_size.y * CFConst.PLAY_AREA_SCALE.y > get_viewport().size.y:
#					_target_position.y = get_viewport().size.y - $Control.rect_size.y * CFConst.PLAY_AREA_SCALE.y
				_add_tween_position(position, _target_position, 0.25)
				# The below ensures a card dropped from the hand will not
				# retain a slight rotation.
				# We check if the card already has been rotated to a different
				# card_cotation
				if not int($Control.rect_rotation) in [0,90,180,270]:
					_add_tween_rotation($Control.rect_rotation, _target_rotation, 0.25)
				# We want cards on the board to be slightly smaller than in hand.
				if not scale.is_equal_approx(CFConst.PLAY_AREA_SCALE):
					_add_tween_scale(scale, CFConst.PLAY_AREA_SCALE, 0.5,
							Tween.TRANS_BOUNCE, Tween.EASE_OUT)
				$Tween.start()
				state = CardState.ON_PLAY_BOARD

		CardState.FOCUSED_ON_BOARD:
			# Used when card is focused on by the mouse hovering over it while it is on the board.
			set_focus(true)
			set_control_mouse_filters(true)
			buttons.set_active(true)
			# We don't change state yet, only when the focus is removed from this card

		CardState.IN_PILE:
			set_focus(false)
			set_control_mouse_filters(false)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			if scale != Vector2(1,1):
				scale = Vector2(1,1)
			set_is_faceup(get_parent().faceup_cards, true)

		CardState.IN_POPUP:
			# We make sure that a card in a popup stays in its position
			# Unless moved
			set_focus(false)
			set_control_mouse_filters(true)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			if modulate[3] != 1:
				modulate[3] = 1
			if scale != Vector2(0.75,0.75):
				scale = Vector2(0.75,0.75)
			if position != Vector2(0,0):
				position = Vector2(0,0)

		CardState.FOCUSED_IN_POPUP:
			# Used when the card is displayed in the popup grid container
			set_focus(true)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)

		CardState.VIEWPORT_FOCUS:
			set_focus(false)
			set_control_mouse_filters(false)
			buttons.set_active(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			$Control.rect_rotation = 0
			targeting_arrow.complete_targeting()
			$Control/Tokens.visible = false
			# We scale the card dupe to allow the player a better viewing experience
			scale = Vector2(1.5,1.5)
			# If the card has already been been viewed while down,
			# we allow the player hovering over it to see it
			if not is_faceup:
				if is_viewed:
					_flip_card($Control/Back,$Control/Front, true)
				else:
					# We slightly reduce the colour intensity of the dupe
					# As its enlarged state makes it glow too much
					var current_colour = $Control/Back.modulate
					$Control/Back.modulate = current_colour * 0.95


# Get the angle on the ellipse
func _get_angle_by_index(index_diff = null) -> float:
	var index = get_my_card_index()
	var hand_size = get_parent().get_card_count()
	# This to prevent div/0 errors because the card will not be
	# reported when it's being dragged
	if hand_size == 0:
		hand_size = 1
	var half
	half = (hand_size - 1) / 2.0
	var card_angle_max: float = 15
	var card_angle_min: float = 5
	# Angle between cards
	var card_angle = max(min(60 / hand_size, card_angle_max), card_angle_min)
	# When foucs hand, the card needs to be offset by a certain angle
	# The current practice is just to find a suitable expression function, if there is a better function, please replace this function: - sign(index_diff) * (1.95-0.3*index_diff*index_diff) * min(card_angle,5)
	if index_diff != null:
		return 90 + (half - index) * card_angle \
				- sign(index_diff) * (1.95 - 0.3 * index_diff * index_diff) \
				* min(card_angle, 5)
	else:
		return 90 + (half - index) * card_angle


# Get card angle in hand by index that use oval shape
# The angle of the normal on the ellipse
func _get_oval_angle_by_index(
		angle = null,
		index_diff = null,
		hor_rad = null,
		ver_rad = null) -> float:
	if not angle:
		# Get the angle from the point on the oval to the center of the oval
		angle = _get_angle_by_index(index_diff)
	var parent_control
	if not hor_rad:
		parent_control = get_parent().get_node('Control')
		hor_rad = parent_control.rect_size.x * 0.5 * 1.5
	if not ver_rad:
		parent_control = get_parent().get_node('Control')
		ver_rad = parent_control.rect_size.y * 1.5
	var card_angle
	if angle == 90:
		card_angle = 90
	else:
		# Convert oval angle to normal angle
		card_angle= rad2deg(atan(- ver_rad / hor_rad / tan(deg2rad(angle))))
		card_angle = card_angle + 90
	return card_angle


# Calculate the position after the rotation has been calculated that use oval shape
func _recalculate_position_use_oval(index_diff = null)-> Vector2:
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	var parent_control = get_parent().get_node('Control')
	# Oval hor rad, rect_size.x*0.5*1.5 it’s an empirical formula,
	# that's been tested to feel good.
	var hor_rad: float = parent_control.rect_size.x * 0.5 * 1.5
	# Oval ver rad, rect_size.y * 1.5 it’s an empirical formula,
	# that's been tested to feel good.
	var ver_rad: float = parent_control.rect_size.y * 1.5
	# Get the angle from the point on the oval to the center of the oval
	var angle = _get_angle_by_index(index_diff)
	var rad_angle = deg2rad(angle)
	# Get the direction vector of a point on the oval
	var oval_angle_vector = Vector2(hor_rad * cos(rad_angle),
			- ver_rad * sin(rad_angle))
	# Take the center point of the card as the starting point, the coordinates
	# of the top left corner of the card
	var left_top = Vector2(- $Control.rect_size.x/2, - $Control.rect_size.y/2)
	# Place the top center of the card on the oval point
	var center_top = Vector2(0, - $Control.rect_size.y/2)
	# Get the angle of the card, which is different from the oval angle,
	# the card angle is the normal angle of a certain point
	var card_angle = _get_oval_angle_by_index(angle, null, hor_rad,ver_rad)
	# Displacement offset due to card rotation
	var delta_vector = left_top - center_top.rotated(deg2rad(90 - card_angle))
	# Oval center x
	var center_x = parent_control.rect_size.x / 2 \
			+ parent_control.rect_position.x
	# Oval center y, - parent_control.rect_size.y * 0.25:This method ensures that the card is moved to the proper position
	var center_y = parent_control.rect_size.y * 1.5 \
			+ parent_control.rect_position.y \
			- parent_control.rect_size.y * 0.25
	card_position_x = (oval_angle_vector.x + center_x)
	card_position_y = (oval_angle_vector.y + center_y)
	return(Vector2(card_position_x, card_position_y) + delta_vector)


# Calculate the position that use rectangle
func _recalculate_position_use_rectangle(index_diff = null)-> Vector2:
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	# The number of cards currently in hand
	var hand_size: int = get_parent().get_card_count()
	# The maximum of horizontal pixels we want the cards to take
	# We simply use the size of the parent control container we've defined in
	# the node settings
	var parent_control = get_parent().get_node('Control')
	var max_hand_size_width: float = parent_control.rect_size.x
	# The maximum distance between cards
	# We base it on the card width to allow it to work with any card-size.
	var card_gap_max: float = $Control.rect_size.x * 1.1
	# The minimum distance between cards
	# (less than card width means they start overlapping)
	var card_gap_min: float = $Control.rect_size.x/2
	# The current distance between cards.
	# It is inversely proportional to the amount of cards in hand
	var cards_gap: float = max(min((max_hand_size_width
			- $Control.rect_size.x/2)
			/ hand_size, card_gap_max), card_gap_min)
	# The current width of all cards in hand together
	var hand_width: float = (cards_gap * (hand_size-1)) + $Control.rect_size.x
	# The following just create the vector position to place this specific card
	# in the playspace.
	card_position_x = (max_hand_size_width/2
			- hand_width/2
			+ cards_gap
			* get_my_card_index())
	# Since our control container has the same size as the cards,we start from 0
	# and just offset the card if we want it higher or lower.
	card_position_y = 0
	if index_diff!=null:
		return(Vector2(card_position_x, card_position_y)
				+ Vector2($Control.rect_size.x / index_diff * CFConst.NEIGHBOUR_PUSH, 0))
	else:
		return(Vector2(card_position_x,card_position_y))


# Calculates the rotation the card should have based on its parent.
func _recalculate_rotation(index_diff = null)-> float:
	var calculated_rotation := float(card_rotation)
	if get_parent() == cfc.NMAP.hand and cfc.hand_use_oval_shape:
		calculated_rotation = 90.0 - _get_oval_angle_by_index(null, index_diff)
	return(calculated_rotation)


# Set a label node's text.
# As the string becomes longer, the font size becomes smaller
func _set_label_text(node, value):
	# We do not want some fields, like the name, to be too small.
	# see CardConfig.TEXT_EXPANSION_MULTIPLIER documentation
	var allowed_expansion = CardConfig.TEXT_EXPANSION_MULTIPLIER.get(node.name,1)
	var label_size = node.rect_size
	var label_font = node.get("custom_fonts/font").duplicate()
	var line_height = label_font.get_height()
	# line_spacing should be calculated into rect_size
	var line_spacing = node.get("custom_constants/line_spacing")
	if not line_spacing:
		line_spacing = 3
	# This calculates the amount of vertical pixels the text would take
	# once it was word-wrapped.
	var label_rect_y = label_font.get_wordwrap_string_size(
			value, label_size.x).y \
			/ line_height \
			* (line_height + line_spacing) \
			- line_spacing
	# If the y-size of the wordwrapped text would be bigger than the current
	# available y-size foir this label, we reduce the text, until we
	# it's small enough to stay within the boundaries
	while label_rect_y > label_size.y * allowed_expansion:
		label_font.size = label_font.size - 1
		if label_font.size < 3:
			label_font.size = 2
			break
		label_rect_y = label_font.get_wordwrap_string_size(
				value,label_size.x).y \
				/ line_height \
				* (line_height + line_spacing) \
				- line_spacing
	node.set("custom_fonts/font", label_font)
	node.rect_min_size = label_size
	node.text = value


# Ensures that all filters requested by the script are respected
#
# Will set is_valid to false if any filter does not match reality
func _filter_signal_trigger(card_scripts, trigger_card: Card) -> bool:
	var is_valid = true
	# Here we check that the trigger matches the _request_ for trigger
	# A trigger which requires "another" card, should not trigger
	# when itself causes the effect.
	# For example, a card which rotates itself whenever another card
	# is rotated, should not automatically rotate when itself rotates.
	var trigger = card_scripts.get("trigger", "any")
	if trigger == "self" and trigger_card != self:
		is_valid = false
	if trigger == "another" and trigger_card == self:
		is_valid = false
	return(is_valid)
