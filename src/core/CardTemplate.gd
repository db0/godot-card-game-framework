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
enum{
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

# The possible return codes a function can return
#
# * OK is returned when the function did not end up doing any changes
# * CHANGE is returned when the function modified the card properties in some way
# * FAILED is returned when the function failed to modify the card for some reason
enum _ReturnCode {
	OK,
	CHANGED,
	FAILED,
}

signal initiated_targeting
# Emitted whenever the card has selected a target.
signal target_selected(card)
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
signal card_token_modified(card,trigger,details)
# Emited whenever the card attaches to another
signal card_attached(card,trigger,details)
# Emited whenever the card unattaches from another
signal card_unattached(card,trigger,details)
# Emited whenever the card is targeted by another card.
# This signal is not fired by this card directly, but by the card
# doing the targeting.
# warning-ignore:unused_signal
signal card_targeted(card,trigger,details)


var scripting_engine = load("res://src/core/ScriptingEngine.gd")

# Used to add new token instances to cards
const _TOKEN_SCENE = preload("res://src/core/Token.tscn")
const _CARD_CHOICES_SCENE = preload("res://src/core/CardChoices.tscn")

export var properties :=  {}
# We export this variable to the editor to allow us to add scripts to each card
# object directly instead of only via code.
#
# If this variable is set, it takes precedence over scripts
# found in `CardScriptDefinitions.gd`
#
# See `CardScriptDefinitions.gd` for the proper format of a scripts dictionary
export var scripts := {}
# If true, the card can be attached to other cards and will follow
# their host around the table. The card will always return to its host
# when dragged away
export var is_attachment := false setget set_is_attachment, get_is_attachment
# If true, the card will be displayed faceup. If false, it will be facedown
export var is_faceup  := true setget set_is_faceup, get_is_faceup
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

# Used to store a card succesfully targeted.
# It should be cleared from whichever effect requires a target.
# once it is used
var target_card : Card = null setget set_targetcard, get_targetcard
# Used to store a card targeted via the cost-dry-run mechanism.
# it is reset to null every time the properties check is not valid
var target_dry_run_card : Card = null
# Starting state for each card
var state := IN_PILE
# If this card is hosting other cards,
# this list retains links to their objects in order.
var attachments := []
# If this card is set as an attachment to another card,
# this tracks who its host is.
var current_host_card : Card = null
# A dictionary holding all the tokens placed on this card.
var tokens := {} setget ,get_all_tokens

# To track that this card attempting to target another card.
var _is_targetting := false
# Used when completing targeting to know whether to put the target
# into target_dry_run_card or target_card
var _cost_dry_run := false
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
# Used for looping between brighness scales for the Cardback glow
# The multipliers have to be small, as even small changes increase
# brightness a lot
var _pulse_values := [Color(1.05,1.05,1.05),Color(0.9,0.9,0.9)]
# A flag on whether the token drawer is currently open
var _is_drawer_open := false
# Debug for stuck tweens
var _tween_stuck_time = 0

onready var _tween = $Tween
onready var _flip_tween = $Control/FlipTween
onready var _buttons_tween = $Control/ManipulationButtons/Tween
onready var _pulse_tween = $Control/Back/Pulse
onready var _tokens_tween = $Control/Tokens/Tween

onready var _card_text = $Control/Front/CardText

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
	$Control/FocusHighlight.rect_size = $Control.rect_size + Vector2(6,6)
	$Control/FocusHighlight.rect_position = Vector2(-3,-3)
	# We set the targetting arrow modulation to match our config specification
	$TargetLine.default_color = cfc.TARGETTING_ARROW_COLOUR
	$TargetLine/ArrowHead.color = cfc.TARGETTING_ARROW_COLOUR
	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_Card_area_entered")
	# warning-ignore:return_value_discarded
	connect("area_exited", self, "_on_Card_area_exited")
	# warning-ignore:return_value_discarded
	$TargetLine/ArrowHead/Area2D.connect("area_entered", self, "_on_ArrowHead_area_entered")
	# warning-ignore:return_value_discarded
	$TargetLine/ArrowHead/Area2D.connect("area_exited", self, "_on_ArrowHead_area_exited")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_entered", self, "_on_Card_mouse_entered")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_exited", self, "_on_Card_mouse_exited")
	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", self, "_on_Card_gui_input")
	# warning-ignore:return_value_discarded
	$Control/Tokens/Drawer/VBoxContainer.connect("sort_children", self, "_on_VBoxContainer_sort_children")
	# warning-ignore:return_value_discarded
	for button in $Control/ManipulationButtons.get_children():
		if button.name != "Tween":
			button.connect("mouse_entered",self,"_on_button_mouse_entered")
			button.connect("mouse_exited",self,"_on_button_mouse_exited")
	$Control/ManipulationButtons/Rot90.connect("pressed",self,'_on_Rot90_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/Rot180.connect("pressed",self,'_on_Rot180_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/Flip.connect("pressed",self,'_on_Flip_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/AddToken.connect("pressed",self,'_on_AddToken_pressed')
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/View.connect("pressed",self,'_on_View_pressed')
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists before we connect
	if $Control/Back.has_node('Pulse'):
		# warning-ignore:return_value_discarded
		_pulse_tween.connect("tween_all_completed", self, "_on_Pulse_completed")
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
	if $Tween.is_active() and not cfc.UT: # Debug code for catch potential Tween deadlocks
		_tween_stuck_time += delta
		if _tween_stuck_time > 5 and int(fmod(_tween_stuck_time,3)) == 2 :
			print("Tween Stuck for ",_tween_stuck_time,
					"seconds. Reports leftover runtime: ",$Tween.get_runtime ( ))
			$Tween.remove_all()
			_tween_stuck_time = 0
	else:
		_tween_stuck_time = 0
	if _is_targetting:
		_draw_targeting_arrow()
	_process_card_state()
	# Having to do all these checks due to godotengine/godot#16854
	if _is_drawer_open and not _is_drawer_hovered() and not _is_card_hovered():
		_on_Card_mouse_exited()



func _on_Card_mouse_entered() -> void:
	# This triggers the focus-in effect on the card
	#print(state,":enter:",get_index(), ":", _are_buttons_hovered()) # Debug
	#print($Control/Tokens/Drawer/VBoxContainer.rect_size) # debug
	# We use this variable to check if mouse thinks it changed nodes because
	# it just entered a child node
	if not (_are_buttons_hovered() and not _is_drawer_hovered()) or \
			((_are_buttons_hovered() ) and not get_focus()):
		match state:
			IN_HAND, REORGANIZING, PUSHED_ASIDE:
				if not cfc.card_drag_ongoing:
					#print("focusing:",get_my_card_index()) # debug
					interruptTweening()
					state = FOCUSED_IN_HAND
			ON_PLAY_BOARD:
				state = FOCUSED_ON_BOARD
			# The only way to mouse over a card in a pile, is when
			# it's in a the grid popup
			IN_POPUP:
				state = FOCUSED_IN_POPUP


func _input(event) -> void:
	if event is InputEventMouseButton and \
			event.get_button_index() == 1 and \
			not event.is_pressed() \
			and not _are_buttons_hovered():
		if _is_targetting:
			complete_targeting()
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
		# If the player left clicks, we need to see if it's a double-click
		# or a long click
		if event.get_button_index() == 1 and not _are_buttons_hovered():
			# If it's a double-click, then it's not a card drag
			# But rather it's script execution
			if event.doubleclick:
				cfc.card_drag_ongoing = null
				execute_scripts()
			# If it's a long click it might be because
			# they want to drag the card
			elif event.is_pressed():
				if (cfc.focus_style != cfc.FocusStyle.VIEWPORT and
						(state == FOCUSED_IN_HAND
						or state == FOCUSED_ON_BOARD)) or cfc.focus_style:
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
		if not event.is_pressed() and event.get_button_index() == 1:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Control.set_default_cursor_shape(Input.CURSOR_ARROW)
			cfc.card_drag_ongoing = null
			match state:
				DRAGGED:
					# if the card was being dragged, it's index is very high
					# to always draw above other objects
					# We need to reset it either to the default of 0
					# Or if the card was left overlapping with other cards,
					# the higher index among them
					z_index = 0
					var destination = cfc.NMAP.board
					for obj in get_overlapping_areas():
						if obj.get_class() == 'CardContainer':
							#TODO: Need some more player-obvious logic on
							# what to do if card area overlaps two CardContainers
							destination = obj
					move_to(destination)
					_focus_completed = false
					#emit_signal("card_dropped",self)
		if event.is_pressed() and event.get_button_index() == 2:
			initiate_targeting()
		if not event.is_pressed() and event.get_button_index() == 2:
			complete_targeting()


# Triggers the focus-out effect on the card
func _on_Card_mouse_exited() -> void:
	# On exiting this node, we wait a tiny bit to make sure the mouse didn't
	# just enter a child button
	# If it did, then that button will immediately set a variable to let us know
	# not to restart the focus
	#print(state,":exit:",get_index()) # debug
	#print(_are_buttons_hovered()) # debug
	# We use this variable to check if mouse thinks it changed nodes
	# because it just entered a child node
	if not _are_buttons_hovered() and not _is_drawer_hovered():
		match state:
			FOCUSED_IN_HAND:
				#_focus_completed = false
				# To avoid errors during fast player actions
				if get_parent() in cfc.hands:
					for c in get_parent().get_all_cards():
						# We need to make sure afterwards all card will return
						# to their expected positions
						# Therefore we simply stop all tweens and reorganize the whole hand
						c.interruptTweening()
						# This will also set the state to IN_HAND afterwards
						c.reorganizeSelf()
			FOCUSED_ON_BOARD:
				state = ON_PLAY_BOARD
			FOCUSED_IN_POPUP:
				state = IN_POPUP


# Resizes Token Drawer to min size whenever a token is removed completely.
#
# Without this, the token drawer would stay at the highest size it reached.
func _on_VBoxContainer_sort_children() -> void:
	$Control/Tokens/Drawer/VBoxContainer.rect_size = \
			$Control/Tokens/Drawer/VBoxContainer.rect_min_size
	# We need to resize it's parent too
	$Control/Tokens/Drawer.rect_size = \
			$Control/Tokens/Drawer.rect_min_size


func _on_button_mouse_entered() -> void:
	match state:
		ON_PLAY_BOARD:
			_buttons_tween.remove_all()
			$Control/ManipulationButtons.modulate[3] = 1


# Makes the hoverable buttons invisible when mouse is not hovering over the card
func _on_button_mouse_exited() -> void:
	if not get_focus():
		_buttons_tween.remove_all()
		$Control/ManipulationButtons.modulate[3] = 0


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
	mod_token(valid_tokens[CardFrameworkUtils.randi() % len(valid_tokens)], 1)


# Hover button which allows the player to view a facedown card
func _on_View_pressed() -> void:
	# warning-ignore:return_value_discarded
	set_is_viewed(true)


# Triggers when a card hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as hosts
func _on_Card_area_entered(card: Card) -> void:
	if (card and is_attachment and not card in attachments):
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
			_potential_cards.sort_custom(CardIndexSorter,"sort_index_ascending")
			# Finally we use a method which  handles changing highlights on the
			# top index card
			highlight_potential_card(cfc.HOST_HOVER_COLOUR)


# Triggers when a card stops hovering over another
#
# It clears potential highlights and adjusts potential cards as hosts
func _on_Card_area_exited(card: Card) -> void:
	if card:
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
			card.set_highlight(false)
			# Finally, we make sure we highlight any other cards we're still hovering
			highlight_potential_card(cfc.HOST_HOVER_COLOUR)


# Triggers when a targetting arrow hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as targets.
func _on_ArrowHead_area_entered(card: Card) -> void:
	if card and not card in _potential_cards:
		_potential_cards.append(card)
		_potential_cards.sort_custom(CardIndexSorter,"sort_index_ascending")
		highlight_potential_card(cfc.TARGET_HOVER_COLOUR)


# Triggers when a targetting arrow stops hovering over a card
#
# It clears potential highlights and adjusts potential cards as targets
func _on_ArrowHead_area_exited(card: Card) -> void:
	if card and card in _potential_cards:
		# We remove the card we stopped hovering from the _potential_cards
		_potential_cards.erase(card)
		# And we explicitly hide its cards focus since we don't care about it anymore
		card.set_highlight(false)
		# Finally, we make sure we highlight any other cards we're still hovering
		highlight_potential_card(cfc.TARGET_HOVER_COLOUR)


# Reverses the card back pulse and starts it again
func _on_Pulse_completed() -> void:
	# We only pulse the card if it's face-down and on the board
	if not is_faceup: #and get_parent() == cfc.NMAP.board:
		_pulse_values.invert()
		_start_pulse()
	else:
		_stop_pulse()


# This function handles filling up the card's labels according to its
# card definition dictionary entry.
func setup(cname: String) -> void:
	# The properties of the card should be already stored in cfc
	set_card_name(cname)
	properties = cfc.card_definitions.get(cname)
	for label in properties.keys():
		# These are standard properties which is simple a String to add to the
		# label.text field
		if label in CardConfig.PROPERTIES_STRINGS:
			_set_label_text($Control/Front/CardText.get_node(label),
					properties[label])
			# $Control/Front/CardText.get_node(label).text = properties[label]
			if properties[label]=="":
				$Control/Front/CardText.get_node(label).visible = false
		# These are int or float properties which need to be converted
		# to a string with some formatting.
		#
		# In this demo, the format is defined as: "labelname: value"
		elif label in CardConfig.PROPERTIES_NUMBERS:
			_set_label_text($Control/Front/CardText.get_node(label),label
					+ ": " + str(properties[label]))
		# These are arrays of properties which are put in a label with a simple
		# Join character
		elif label in CardConfig.PROPERTIES_ARRAYS:
			_set_label_text($Control/Front/CardText.get_node(label),
					CardFrameworkUtils.array_join(properties[label],
					cfc.ARRAY_PROPERTY_JOIN))


# Setter for _is_attachment
func set_is_attachment(value: bool) -> void:
	is_attachment = value


# Getter for _is_attachment
func get_is_attachment() -> bool:
	return is_attachment


# Setter for target_card
func set_targetcard(card: Card) -> void:
	target_card = card


# Getter for target_card
func get_targetcard() -> Card:
	return target_card


# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# * Returns _ReturnCode.CHANGED if the card actually changed rotation
# * Returns _ReturnCode.OK if the card was already in the correct rotation
func set_is_faceup(value: bool, instant := false, check := false) -> int:
	var retcode: int
	if value == is_faceup:
		retcode = _ReturnCode.OK
	elif not check:
		if _is_drawer_open:
			_token_drawer(false)
		# We make sure to remove other tweens of the same type to avoid a deadlock
		is_faceup = value
		# When we change faceup state, we reset the is_viewed to false
		if set_is_viewed(false) == _ReturnCode.FAILED:
			print("ERROR: Something went unexpectedly in set_is_faceup")
		if value:
			_flip_card($Control/Back, $Control/Front,instant)
			$Control/ManipulationButtons/View.visible = false
			_stop_pulse()
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
			$Control/ManipulationButtons/View.visible = true
#			if get_parent() == cfc.NMAP.board:
			_start_pulse()
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
		retcode = _ReturnCode.CHANGED
		emit_signal("card_flipped", self, "card_flipped", {"is_faceup": value})
	# If we're doing a check, then we just report CHANGED.
	else:
		retcode = _ReturnCode.CHANGED
	return retcode


# Getter for is_faceup
func get_is_faceup() -> bool:
	return is_faceup


# Setter for is_faceup
#
# Flips the card face-up/face-down
#
# * Returns _ReturnCode.CHANGED if the card actually changed view status
# * Returns _ReturnCode.OK if the card was already in the correct view status
# * Returns _ReturnCode.FAILED if changing the status is now allowed
func set_is_viewed(value: bool) -> int:
	var retcode: int
	if value == true:
		if is_faceup == true:
			# Players can already see faceup cards
			retcode = _ReturnCode.FAILED
		elif value == is_viewed:
			retcode = _ReturnCode.OK
		else:
			is_viewed = true
			if get_parent() != null and get_tree().get_root().has_node('Main'):
				var dupe_front = cfc.NMAP.main._previously_focused_cards.back().get_node("Control/Front")
				var dupe_back = cfc.NMAP.main._previously_focused_cards.back().get_node("Control/Back")
				_flip_card(dupe_back, dupe_front, true)
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = true
			retcode = _ReturnCode.CHANGED
			# We only emit a signal when we view the card
			# not when we unview it as that happens naturally
			emit_signal("card_viewed", self, "card_viewed",  {"is_viewed": true})
	else:
		if value == is_viewed:
			retcode = _ReturnCode.OK
		elif is_faceup == true:
			retcode = _ReturnCode.CHANGED
			is_viewed = false
			$Control/Back/VBoxContainer/CenterContainer/Viewed.visible = false
		else:
			# We don't allow players to unview cards
			retcode = _ReturnCode.FAILED
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
# * Returns _ReturnCode.CHANGED if the card actually changed rotation.
# * Returns _ReturnCode.OK if the card was already in the correct rotation.
# * Returns _ReturnCode.FAILED if an invalid rotation was specified.
func set_card_rotation(value: int, toggle := false, start_tween := true, check := false) -> int:
	var retcode
	# For cards we only allow orthogonal degrees of rotation
	# If it's not, we consider the request failed
	if not value in [0,90,180,270]:
		retcode = _ReturnCode.FAILED
	# We only allow rotating card while they're on the board
	elif value != 0 and get_parent() != cfc.NMAP.board:
		retcode = _ReturnCode.FAILED
	# If the card is already in the specified rotation
	# and a toggle was not requested, we consider we did nothing
	elif value == card_rotation and not toggle:
		retcode = _ReturnCode.OK
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

		retcode = _ReturnCode.CHANGED
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
func move_to(targetHost: Node2D,
		index := -1,
		boardPosition := Vector2(-1,-1)) -> void:
#	if cfc.focus_style:
#		# We make to sure to clear the viewport focus because
#		# the mouse exited signal will not fire after drag&drop in a container
#		cfc.NMAP.main.unfocus()
	# We need to store the parent, because we won't be able to know it later
	var parentHost = get_parent()
	# We want to keep the token drawer closed during movement
	if _is_drawer_open:
		_token_drawer(false)
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
		if targetHost in cfc.hands:
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
			state = MOVING_TO_CONTAINER
			emit_signal("card_moved_to_hand",
					self,
					"card_moved_to_hand",
					 {"destination": targetHost, "source": parentHost})
			# We reorganize the left over cards in hand.
			for c in targetHost.get_all_cards():
				if c != self:
					c.interruptTweening()
					c.reorganizeSelf()
			if set_is_faceup(true) == _ReturnCode.FAILED:
				print("ERROR: Something went unexpectedly in set_is_faceup")
		elif targetHost in cfc.piles:
			# The below checks if the container we're moving is in popup
			# If the card is also in a popup, we assume we're moving back
			# to the same container, so we do nothing
			# The finite state machine  will reset the card to its position
			if "CardPopUpSlot" in parentHost.name:
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
				state = MOVING_TO_CONTAINER
				emit_signal("card_moved_to_pile",
						self,
						"card_moved_to_pile",
						{"destination": targetHost, "source": parentHost})
				if set_is_faceup(targetHost.faceup_cards) == _ReturnCode.FAILED:
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
			state = DROPPING_TO_BOARD
			emit_signal("card_moved_to_board",
					self,
					"card_moved_to_board",
					{"destination": targetHost, "source": parentHost})
		if parentHost in cfc.hands:
			# We also want to rearrange the hand when we take cards out of it
			for c in parentHost.get_all_cards():
				# But this time we don't want to rearrange ourselves, as we're
				# in a different container by now
				if c != self and c.state != DRAGGED:
					c.interruptTweening()
					c.reorganizeSelf()
		elif parentHost == cfc.NMAP.board:
			# If the card was or had attachments and it is removed from the table,
			# all attachments status is cleared
			_clear_attachment_status()
			# If the card has tokens, and tokens_only_on_board is true
			# we remove all tokens
			if cfc.tokens_only_on_board:
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.queue_free()
			# We also make sure the card buttons don't stay visible or enabled
			_buttons_tween.remove_all()
			$Control/ManipulationButtons.modulate[3] = 0
	else:
		# Here we check what to do if the player just moved the card back
		# to the same container
		if parentHost == cfc.NMAP.hand:
			state = IN_HAND
			reorganizeSelf()
		if parentHost == cfc.NMAP.board:
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
						* cfc.ATTACHMENT_OFFSET))
			else:
				_determine_target_position_from_mouse()
				raise()
			state = ON_PLAY_BOARD
	# Just in case there's any leftover potential host highlights
	if len(_potential_cards):
		for card in _potential_cards:
			card.set_highlight(false)
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
		# CardScriptDefinitions.gd should contain scripts for all defined cards
		card_scripts = CardFrameworkUtils.find_card_script(card_name, trigger)

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
		ON_PLAY_BOARD,FOCUSED_ON_BOARD:
			# We assume only faceup cards can execute scripts on the board
			if is_faceup:
				state_exec ="board"
		IN_HAND,FOCUSED_IN_HAND:
				state_exec ="hand"
		IN_POPUP,FOCUSED_IN_POPUP:
				state_exec ="pile"
	state_scripts = card_scripts.get(state_exec, [])

	# Here we check for confirmation of optional trigger effects
	# There should be an SP.KEY_IS_OPTIONAL definition per state
	# E.g. if board scripts are optional, but hand scripts are not
	# Then you'd include an "is_optional_board" key at the same level as "board"
	var confirm_return = CardFrameworkUtils.confirm(
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
		current_host_card.set_highlight(false)
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
				* cfc.ATTACHMENT_OFFSET))
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
func reorganizeSelf() ->void:
	# We clear the card as being in-focus if we're asking it to be reorganized
	_focus_completed = false
	match state:
		IN_HAND, FOCUSED_IN_HAND, PUSHED_ASIDE:
			_target_position = recalculate_position()
			_target_rotation = _recalculate_rotation()
			state = REORGANIZING
	# This second match is  to prevent from changing the state
	# when we're doing fancy movement
	# and we're still in the first part (which is waiting on an animation yield).
	# Instead, we just change the target position transparently,
	# and when the second part of the animation begins
	# it will automatically pick up the right location.
	match state:
		MOVING_TO_CONTAINER:
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
			or state != MOVING_TO_CONTAINER)):
		$Tween.remove_all()
		state = IN_HAND


# Changes card focus (highlighted and put on the focus viewport)
func set_focus(requestedFocus: bool) -> void:
	 # We use an if to avoid performing constant operations in _process
	if $Control/FocusHighlight.visible != requestedFocus and \
			$Control/FocusHighlight.modulate == cfc.FOCUS_HOVER_COLOUR:
		$Control/FocusHighlight.visible = requestedFocus
	if cfc.focus_style: # value 0 means only scaling focus
		if requestedFocus:
			cfc.NMAP.main.focus_card(self)
		else:
			cfc.NMAP.main.unfocus(self)
	# Tokens drawer is an optional node, so we check if it exists
	# We also generally only have tokens on the table
	if $Control.has_node("Tokens"):
		_token_drawer(requestedFocus)
#		if name == "Card" and get_parent() == cfc.NMAP.board:
#			print(requestedFocus)


# Tells us the focus-state of a card
#
# Returns true if card is currently in focus, else false
func get_focus() -> bool:
	var focusState = false
	match state:
		FOCUSED_IN_HAND, FOCUSED_ON_BOARD:
			focusState = true
	return(focusState)


# Adds a token to the card
#
# If the token of that name doesn't exist, it creates it according to the config.
#
# If the amount of existing tokens of that type drops to 0 or lower,
# the token node is also removed.
func mod_token(token_name : String, mod := 1, set_to_mod := false, check := false) -> int:
	var retcode : int
	# If the player requested a token name that has not been defined by the game
	# we return a failure
	if not cfc.TOKENS_MAP.get(token_name, null):
		retcode = _ReturnCode.FAILED
	else:
		var token : Token = get_all_tokens().get(token_name, null)
		# If the token does not exist in the card, we add its node
		# and set it to 1
		if not token and mod > 0:
			token = _TOKEN_SCENE.instance()
			token.setup(token_name)
			$Control/Tokens/Drawer/VBoxContainer.add_child(token)
		# If the token node of this name has already been added to the card
		# We just increment it by 1
		if not token and mod == 0:
			retcode = _ReturnCode.OK
		# For cost dry-runs, we don't want to modify the tokens at all.
		# Just check if we could.
		elif check:
			# For a  cost dry run, we can only return FAILED
			# when removing tokens as it's always possible to add new ones
			if mod < 0:
				# If the current tokens are equal or higher, then we can
				# remove the requested amount and therefore return CHANGED.
				if token.count + mod >= 0:
					retcode = _ReturnCode.CHANGED
				# If we cannot remove the full amount requested
				# we return FAILED
				else:
					retcode = _ReturnCode.FAILED
			else:
				retcode = _ReturnCode.CHANGED
		else:
			var prev_value = token.count
			# The set_to_mod value means that we want to set the tokens to the
			# exact value specified
			if set_to_mod:
				token.count = mod
			else:
				token.count += mod
			# We store the count in a new variable, to be able to use it
			# in the signal even after the token is deinstanced.
			var new_value = token.count
			if token.count == 0:
				token.queue_free()
		# if the drawer has already been opened, we need to make sure
		# the new token name will also appear
			elif _is_drawer_open:
				token.expand()
			retcode = _ReturnCode.CHANGED
			emit_signal("card_token_modified", self, "card_token_modified",
					{"token_name": token.get_token_name(),
					"previous_token_value": prev_value,
					"new_token_value": new_value})
	return(retcode)


# Returns a dictionary of card tokens on this card.
#
# * Key is the name of the token.
# * Value is the token scene.
func get_all_tokens() -> Dictionary:
	var found_tokens := {}
	for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
		found_tokens[token.name] = token
	return found_tokens


# Returns the token node of the provided name or null if not found.
func get_token(token_name: String) -> Token:
	return(get_all_tokens().get(token_name,null))


# Changes card highlight colour.
func set_highlight(requestedFocus: bool, hoverColour = cfc.HOST_HOVER_COLOUR) -> void:
	$Control/FocusHighlight.visible = requestedFocus
	if requestedFocus:
		$Control/FocusHighlight.modulate = hoverColour
	else:
		$Control/FocusHighlight.modulate = cfc.FOCUS_HOVER_COLOUR


# Returns the Card's index position among other card objects
func get_my_card_index() -> int:
	return get_parent().get_card_index(self)


# Goes through all the potential cards we're currently hovering onto with a card
# or targetting arrow, and highlights the one with the highest index among
# their common parent.
# It also colours the highlight with the provided colour
func highlight_potential_card(colour : Color) -> void:
	for idx in range(0,len(_potential_cards)):
			# The last card in the sorted array is always the highest index
		if idx == len(_potential_cards) - 1:
			_potential_cards[idx].set_highlight(true,colour)
		else:
			_potential_cards[idx].set_highlight(false)


# Will generate a targeting arrow on the card which will follow the mouse cursor.
# The top card hovered over by the mouse cursor will be highlighted
# and will become the target when complete_targeting() is called
func initiate_targeting(dry_run := false) -> void:
	_cost_dry_run = dry_run
	_is_targetting = true
	$TargetLine/ArrowHead.visible = true
	$TargetLine/ArrowHead/Area2D.monitoring = true
	emit_signal("initiated_targeting")


# Will end the targeting process.
#
# The top card which is hovered (if any) will become the target and inserted
# into the target_card property for future use.
func complete_targeting() -> void:
	if len(_potential_cards) and _is_targetting:
		var tc = _potential_cards.back()
		# We don't want to emit a signal, if the card is a dummy viewport card
		# or we already selected a target during dry-run
		if get_parent() != null and get_parent().name != "Viewport" \
				and not target_dry_run_card:
			# We make the targeted card also emit a targeting signal for automation
			tc.emit_signal("card_targeted", tc, "card_targeted",
					{"targeting_source": self})
		# We use the _cost_dry_run variable when the targeting is happening
		# as part of the checking for costs. We store the target card
		# in a different variable, which is reused during the normal execution
		# of the script, instead of looking for a target again
		if _cost_dry_run:
			target_dry_run_card = tc
		else:
			target_card = tc
#		print("Targeting Demo: ",
#				self.name," targeted ",
#				target_card.name, " in ",
#				target_card.get_parent().name)
		emit_signal("target_selected",target_card)
	_is_targetting = false
	$TargetLine.clear_points()
	$TargetLine/ArrowHead.visible = false
	$TargetLine/ArrowHead/Area2D.monitoring = false

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


# Changes the hosted Manipulation button node mouse filters
#
# * When set to false, buttons cannot receive inputs anymore
#    (this is useful when card is in hand or a pile)
# * When set to true, buttons can receive inputs again
func set_manipulation_button_mouse_filters(value = true) -> void:
	var button_filter := 1
	# We also want the buttons disabled while the card is being targeted
	# with a tarteting arrow.
	# We do not want to activate the buttons when a player is trying to
	# select the card for an effect.
	if not value or $Control/FocusHighlight.modulate == cfc.TARGET_HOVER_COLOUR:
		button_filter = 2
	# We do a comparison first, to make sure we avoid unnecessary operations
	for button in $Control/ManipulationButtons.get_children():
		if button as Button and button.mouse_filter != button_filter:
			button.mouse_filter = button_filter


# Get card position in hand by index
# if use oval shape, the card has a certain offset according to the angle
func recalculate_position(index_diff = null) -> Vector2:
	if cfc.hand_use_oval_shape:
		return _recalculate_position_use_oval(index_diff)
	return _recalculate_position_use_rectangle(index_diff)


class CardIndexSorter:
	# Used with sort_custom to find the highest child index among multiple cards
	static func sort_index_ascending(c1: Card, c2: Card):
		if c1.get_my_card_index() < c2.get_my_card_index():
			return true
		return false


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
					card.state == ON_PLAY_BOARD:
				card.global_position = global_position + \
						Vector2(0,(attach_index + 1) \
						* $Control.rect_size.y \
						* cfc.ATTACHMENT_OFFSET)


# We're using this helper function, to allow our mouse-position relevant code
# to work during integration testing
# Returns either the adjusted global mouse position
# or a fake mouse position provided by integration testing
func _determine_global_mouse_pos() -> Vector2:
	var mouse_position
	var zoom = Vector2(1,1)
	# We have to do the below offset hack due to godotengine/godot#30215
	# This is caused because we're using a viewport node and
	# scaling the game in full-creen.
	if get_viewport().has_node("Camera2D"):
		zoom = get_viewport().get_node("Camera2D").zoom
	var offset_mouse_position = \
			get_tree().current_scene.get_global_mouse_position() \
			- get_viewport_transform().origin
	offset_mouse_position *= zoom
	#var scaling_offset = get_tree().get_root().get_node('Main').get_viewport().get_size_override() * OS.window_size
	if cfc.UT: mouse_position = cfc.NMAP.board._UT_mouse_position
	else: mouse_position = offset_mouse_position
	return mouse_position



# Returns the global mouse position but ensures it does not exit the
# viewport limits when including the card rect
#
# Returns the adjusted global_mouse_position
func _determine_board_position_from_mouse() -> Vector2:
	var targetpos: Vector2 = _determine_global_mouse_pos()
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
	if _target_position.x + $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x \
			> get_viewport().size.x:
		_target_position.x = get_viewport().size.x \
				- $Control.rect_size.x \
				* cfc.PLAY_AREA_SCALE.x
	if _target_position.y + $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y \
			> get_viewport().size.y:
		_target_position.y = get_viewport().size.y \
				- $Control.rect_size.y \
				* cfc.PLAY_AREA_SCALE.y


# Instructs the card to move aside for another card enterring focus
func _pushAside(targetpos: Vector2, target_rotation: float) -> void:
	interruptTweening()
	_target_position = targetpos
	_target_rotation = target_rotation
	state = PUSHED_ASIDE

# Pick up a card to drag around with the mouse.
func _start_dragging() -> void:
	# When dragging we want the dragged card to always be drawn above all else
	z_index = 99
	# We have use parent viewport to calculate global_position
	# due to godotengine/godot#30215
	# This is caused because we're using a viewport node and scaling the game
	# in full-creen.
	if not cfc.UT:
		if ProjectSettings.get("display/window/stretch/mode") != 'disabled':
			get_tree().current_scene.get_viewport().warp_mouse(global_position)
		# However the above messes things if we don't have stretch mode,
		# so we ignore it then
		else:
			get_viewport().warp_mouse(global_position)
	state = DRAGGED
	if get_parent() in cfc.hands:
		# While we're dragging the card from hand, we want the other cards
		# to move to their expected position in hand
		for c in get_parent().get_all_cards():
			if c != self:
				c.interruptTweening()
				c.reorganizeSelf()


# Determines the state a card should have,
# based on the card's container grouping.
#
# This is needed because some states are generic
# and don't always know the state the card should be afterwards
func _determine_idle_state() -> void:
	if get_parent() in cfc.hands:
		state = IN_HAND
	# The extra if is in case the ViewPopup is currently active when the card
	# is being moved into the container
	elif get_parent() in cfc.piles:
		state = IN_PILE
	elif "CardPopUpSlot" in get_parent().name:
		state = IN_POPUP
	else:
		state = ON_PLAY_BOARD


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


# Detects when the mouse is still hovering over the buttons area.
#
# We need to detect this extra, because the buttons restart event propagation.
#
# This means that the Control parent, will send a mouse_exit signal
# when the mouse enter a button rect
# which will make the buttons disappear again.
#
# So we make sure buttons stay visible while the mouse is on top.
#
# This is all necessary as a workaround for
# https://github.com/godotengine/godot/issues/16854
#
# Returns true if the mouse is hovering any of the buttons, else false
func _are_buttons_hovered() -> bool:
	var ret = false
	for button in $Control/ManipulationButtons.get_children():
		if button as Button \
				and button.is_hovered() \
				and button.modulate.a == 1:
			ret = true
#	if (_determine_global_mouse_pos().x
#			>= $Control/ManipulationButtons.rect_global_position.x and
#			_determine_global_mouse_pos().y
#			>= $Control/ManipulationButtons.rect_global_position.y and
#			_determine_global_mouse_pos().x
#			<= $Control/ManipulationButtons.rect_global_position.x
#			+ $Control/ManipulationButtons.rect_size.x and
#			_determine_global_mouse_pos().y
#			<= $Control/ManipulationButtons.rect_global_position.y
#			+ $Control/ManipulationButtons.rect_size.y):
#		ret = true
	return(ret)


# Detects when the mouse is still hovering over the tokens area.
#
# We need to detect this extra, for the same reasons as the targetting buttons
# If we do not, the buttons continuously try to open and close.
#
# Returns true if the mouse is hovering over the token drawer, else false
func _is_drawer_hovered() -> bool:
	var ret = false
	if (_determine_global_mouse_pos().x
		>= $Control/Tokens/Drawer.rect_global_position.x and
		_determine_global_mouse_pos().y
		>= $Control/Tokens/Drawer.rect_global_position.y and
		_determine_global_mouse_pos().x
		<= $Control/Tokens/Drawer.rect_global_position.x
		+ $Control/Tokens/Drawer.rect_size.x and
		_determine_global_mouse_pos().y
		<= $Control/Tokens/Drawer.rect_global_position.y
		+ $Control/Tokens/Drawer.rect_size.y):
		ret = true
	return(ret)


# Detects when the mouse is still hovering over the card
#
# We need to detect this extra, for the same reasons as the targetting buttons
# In case the mouse was hovering over the tokens area and just exited
#
# Returns true if the mouse is hovering over the card, else false
func _is_card_hovered() -> bool:
	var ret = false
	if (_determine_global_mouse_pos().x
			>= $Control.rect_global_position.x and
			_determine_global_mouse_pos().y
			>= $Control.rect_global_position.y and
			_determine_global_mouse_pos().x
			<= $Control.rect_global_position.x
			+ $Control.rect_size.x and
			_determine_global_mouse_pos().y
			<= $Control.rect_global_position.y
			+ $Control.rect_size.y):
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
		for n in [$Control/Front, $Control/Back, $Control/FocusHighlight]:
			_flip_tween.remove(n,'rect_scale')
			_flip_tween.remove(n,'rect_position')
		_flip_tween.interpolate_property(to_invisible,'rect_scale',
				to_invisible.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		_flip_tween.interpolate_property(to_invisible,'rect_position',
				to_invisible.rect_position, Vector2(
				to_invisible.rect_size.x/2,0), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		_flip_tween.interpolate_property($Control/FocusHighlight,'rect_scale',
				$Control/FocusHighlight.rect_scale, Vector2(0,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_IN)
		# The highlight is larger than the card size, but also offet a big
		# so that it's still centered. This way its borders only extend
		# over the card borders. We need to offest to the right location.
		_flip_tween.interpolate_property($Control/FocusHighlight,'rect_position',
				$Control/FocusHighlight.rect_position, Vector2(
				($Control/FocusHighlight.rect_size.x-3)/2,0), 0.4,
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
		_flip_tween.interpolate_property($Control/FocusHighlight,'rect_scale',
				$Control/FocusHighlight.rect_scale, Vector2(1,1), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.interpolate_property($Control/FocusHighlight,'rect_position',
				$Control/FocusHighlight.rect_position, Vector2(-3,-3), 0.4,
				Tween.TRANS_QUAD, Tween.EASE_OUT)
		_flip_tween.start()

# Draws a curved arrow, from the center of a card, to the mouse pointer
func _draw_targeting_arrow() -> void:
	# This variable calculates the card center's position on the whole board
	var centerpos = global_position + $Control.rect_size/2*scale
	# We want the line to be drawn anew every frame
	$TargetLine.clear_points()
	# The final position is the mouse position,
	# but we offset it by the position of the card center on the map
	var final_point =  _determine_global_mouse_pos() - (position + $Control.rect_size/2)
	var curve = Curve2D.new()
#		var middle_point = centerpos + (get_global_mouse_position() - centerpos)/2
#		var middle_dir_to_vpcenter = middle_point.direction_to(get_viewport().size/2)
#		var offmid = middle_point + middle_dir_to_vpcenter * 50
	# Our starting point has to be translated to the local position of the Line2D node
	# The out control point is the direction to the screen center,
	# with a magnitude that I found via trial and error to look good
	curve.add_point($TargetLine.to_local(centerpos),
			Vector2(0,0),
			centerpos.direction_to(get_viewport().size/2) * 75)
#		curve.add_point($TargetLine.to_local(offmid), Vector2(0,0), Vector2(0,0))
	# Our end point also has to be translated to the local position of the Line2D node
	# The in control point is likewise the direction to the screen center
	# with a magnitude that I found via trial and error to look good
	curve.add_point($TargetLine.to_local(position +
			$Control.rect_size/2 + final_point),
			Vector2(0, 0), Vector2(0, 0))
	# Finally we use the Curve2D object to get the points which will be drawn
	# by our lined2D
	$TargetLine.set_points(curve.get_baked_points())
	# We place the arrowhead to start from the last point in the line2D
	$TargetLine/ArrowHead.position = $TargetLine.get_point_position(
			$TargetLine.get_point_count( ) - 1)
	# We delete the last 3 Line2D points, because the arrowhead will
	# be covering those areas
	for _del in range(1,3):
		$TargetLine.remove_point($TargetLine.get_point_count( ) - 1)
	# We setup the angle the arrowhead is pointing by finding the angle of
	# the last point on the line towards the mouse position
	$TargetLine/ArrowHead.rotation = $TargetLine.get_point_position(
				$TargetLine.get_point_count( ) - 1).direction_to(
				$TargetLine.to_local(
				position + $Control.rect_size/2 + final_point)).angle()


# Triggers the looping card back pulse
# The pulse increases and decreases the brightness of the glow
func _start_pulse():
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists
	if $Control/Back.has_node('Pulse'):
		#** CAREFUL **#
		# This fails integration test when I replace it with _pulse_tween
		# I need to investigate why.
		$Control/Back/Pulse.interpolate_property($Control/Back,'modulate',
				_pulse_values[0], _pulse_values[1], 2,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Control/Back/Pulse.start()


# Disables the looping card back pulse
func _stop_pulse():
	# We want to allow anyone to remove the Pulse node if wanted
	# So we check if it exists
	if $Control/Back.has_node('Pulse'):
		$Control/Back/Pulse.remove_all()
		$Control/Back.modulate = Color(1,1,1)


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
		IN_HAND:
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
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

		FOCUSED_IN_HAND:
			# Used when card is focused on by the mouse hovering over it.
			# We increase the z_index to allow the focused card appear
			# always over its neighbours
			z_index = 1
			set_focus(true)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0,false,false)
			if not $Tween.is_active() and \
					not _focus_completed and \
					cfc.focus_style != cfc.FocusStyle.VIEWPORT:
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
						c.reorganizeSelf()
				# When zooming in, we also want to move the card higher,
				# so that it's not under the screen's bottom edge.
				_target_position = expected_position \
						- Vector2($Control.rect_size.x \
						* 0.25,$Control.rect_size.y \
						* 0.5 + cfc.NMAP.hand.bottom_margin)
				_target_rotation = expected_rotation
				# We make sure to remove other tweens of the same type
				# to avoid a deadlock
				_add_tween_position(expected_position, _target_position)
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

		MOVING_TO_CONTAINER:
			# Used when moving card between places
			# (i.e. deck to hand, hand to discard etc)
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(false)
			set_manipulation_button_mouse_filters(false)
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
				if state == MOVING_TO_CONTAINER:
					_add_tween_position(position, _target_position, 0.35,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
					_add_tween_rotation($Control.rect_rotation,_target_rotation)
					$Tween.start()
					yield($Tween, "tween_all_completed")
					_determine_idle_state()
				_fancy_move_second_part = false

		REORGANIZING:
			# Used when reorganizing the cards in the hand
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0,false,false)
			if not $Tween.is_active():
				$Tween.remove(self,'position') #
				_add_tween_position(position, _target_position, 0.4)
				if not scale.is_equal_approx(Vector2(1,1)):
					_add_tween_scale(scale, Vector2(1,1),0.4)
				_add_tween_rotation($Control.rect_rotation,_target_rotation)
				$Tween.start()
				state = IN_HAND

		PUSHED_ASIDE:
			# Used when card is being pushed aside due to the focusing of a neighbour.
			z_index = 0
			set_focus(false)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
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

		DRAGGED:
			# Used when the card is dragged around the game with the mouse
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
			if (not $Tween.is_active() and
				not scale.is_equal_approx(cfc.card_scale_while_dragging) and
				get_parent() != cfc.NMAP.board):
				_add_tween_scale(scale, cfc.card_scale_while_dragging, 0.2,
						Tween.TRANS_SINE, Tween.EASE_IN)
				$Tween.start()
			# We need to capture the mouse cursos in the window while dragging
			# because if the player drags the cursor outside the window and unclicks
			# The control will not receive the mouse input
			# and this will stay dragging forever
			if not cfc.UT: Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			$Control.set_default_cursor_shape(Input.CURSOR_CROSS)
			# We set the card to be centered on the mouse cursor to allow
			# the player to properly understand where it will go once dropped.
			global_position = _determine_board_position_from_mouse()# - $Control.rect_size/2 * scale
			_organize_attachments()
			# We want to keep the token drawer closed during movement
			if _is_drawer_open:
				_token_drawer(false)

		ON_PLAY_BOARD:
			# Used when the card is idle on the board
			set_focus(false)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(true)
			if not $Tween.is_active() and \
					not scale.is_equal_approx(cfc.PLAY_AREA_SCALE):
				_add_tween_scale(scale, cfc.PLAY_AREA_SCALE, 0.3,
						Tween.TRANS_SINE, Tween.EASE_OUT)
				$Tween.start()
			# This tween hides the container manipulation buttons
			if not _buttons_tween.is_active() and \
					$Control/ManipulationButtons.modulate[3] != 0:
				# We always make sure to clean tweening conflicts
				_buttons_tween.remove_all()
				_buttons_tween.interpolate_property(
						$Control/ManipulationButtons,'modulate',
						$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
				_buttons_tween.start()
			_organize_attachments()

		DROPPING_TO_BOARD:
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
			# Used when dropping the cards to the table
			# When dragging the card, the card is slightly behind the mouse cursor
			# so we tween it to the right location
			if not $Tween.is_active():
				$Tween.remove(self,'position') # We make sure to remove other tweens of the same type to avoid a deadlock
#				_target_position = _determine_board_position_from_mouse()
#				# The below ensures the card doesn't leave the viewport dimentions
#				if _target_position.x + $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x > get_viewport().size.x:
#					_target_position.x = get_viewport().size.x - $Control.rect_size.x * cfc.PLAY_AREA_SCALE.x
#				if _target_position.y + $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y > get_viewport().size.y:
#					_target_position.y = get_viewport().size.y - $Control.rect_size.y * cfc.PLAY_AREA_SCALE.y
				_add_tween_position(position, _target_position, 0.25)
				# The below ensures a card dropped from the hand will not
				# retain a slight rotation.
				# We check if the card already has been rotated to a different
				# card_cotation
				if not int($Control.rect_rotation) in [0,90,180,270]:
					_add_tween_rotation($Control.rect_rotation, _target_rotation, 0.25)
				# We want cards on the board to be slightly smaller than in hand.
				if not scale.is_equal_approx(cfc.PLAY_AREA_SCALE):
					_add_tween_scale(scale, cfc.PLAY_AREA_SCALE, 0.5,
							Tween.TRANS_BOUNCE, Tween.EASE_OUT)
				$Tween.start()
				state = ON_PLAY_BOARD

		FOCUSED_ON_BOARD:
			# Used when card is focused on by the mouse hovering over it while it is on the board.
			# The below tween shows the container manipulation buttons when you hover over them
			set_focus(true)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(true)
			if not _buttons_tween.is_active() and \
					$Control/ManipulationButtons.modulate[3] != 1:
				_buttons_tween.remove_all()
				_buttons_tween.interpolate_property(
						$Control/ManipulationButtons,'modulate',
						$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
						Tween.TRANS_SINE, Tween.EASE_IN)
				_buttons_tween.start()
			# We don't change state yet, only when the focus is removed from this card
#		DROPPING_INTO_PILE:
#			# Used when dropping the cards into a container (Deck, Discard etc)
#			set_focus(false)
#			set_control_mouse_filters(false)
#			if not $Tween.is_active():
#				var intermediate_position: Vector2
#				if cfc.fancy_movement:
#					intermediate_position = get_parent().position - \
#							Vector2(0,$Control.rect_size.y*1.1)
#					$Tween.remove(self,'position')
#					$Tween.interpolate_property(self,'position',
#							position, intermediate_position, 0.25,
#							Tween.TRANS_CUBIC, Tween.EASE_OUT)
#					yield($Tween, "tween_all_completed")
#					if not scale.is_equal_approx(Vector2(1,1)):
#						$Tween.remove(self,'scale')
#						$Tween.interpolate_property(self,'scale',
#								scale, Vector2(1,1), 0.5,
#								Tween.TRANS_BOUNCE, Tween.EASE_OUT)
#					$Tween.start()
#					_fancy_move_second_part = true
#				else:
#					intermediate_position = get_parent().position
#				$Tween.remove(self,'position')
#				$Tween.interpolate_property(self,'position',
#						intermediate_position, get_parent().position, 0.35,
#						Tween.TRANS_SINE, Tween.EASE_IN_OUT)
#				$Tween.start()
#				_determine_idle_state()
#				_fancy_move_second_part = false
#				state = IN_PILE

		IN_PILE:
			set_focus(false)
			set_control_mouse_filters(false)
			set_manipulation_button_mouse_filters(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			if scale != Vector2(1,1):
				scale = Vector2(1,1)

		IN_POPUP:
			# We make sure that a card in a popup stays in its position
			# Unless moved
			set_focus(false)
			set_control_mouse_filters(true)
			set_manipulation_button_mouse_filters(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			if modulate[3] != 1:
				modulate[3] = 1
			if scale != Vector2(0.75,0.75):
				scale = Vector2(0.75,0.75)
			if position != Vector2(0,0):
				position = Vector2(0,0)

		FOCUSED_IN_POPUP:
			# Used when the card is displayed in the popup grid container
			set_focus(true)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)

		VIEWPORT_FOCUS:
			set_focus(false)
			set_control_mouse_filters(false)
			set_manipulation_button_mouse_filters(false)
			# warning-ignore:return_value_discarded
			set_card_rotation(0)
			$Control/ManipulationButtons.modulate[3] = 0
			$Control.rect_rotation = 0
			complete_targeting()
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

# Reveals or Hides the token drawer
#
# The drawer will not appear while another animation is ongoing
# and it will appear only while the card is on the board.
func _token_drawer(drawer_state := true) -> void:
	# I use these vars to avoid writing it all the time and to improve readability
	var tween : Tween = _tokens_tween
	var td := $Control/Tokens/Drawer
	# We want to keep the drawer closed during the flip and movement
	if not tween.is_active() and \
			not _flip_tween.is_active() and \
			not $Tween.is_active():
		# We don't open the drawer if we don't have any tokens at all
		if drawer_state == true and \
				$Control/Tokens/Drawer/VBoxContainer.get_child_count() and \
				(state == ON_PLAY_BOARD or state == FOCUSED_ON_BOARD):
			if not _is_drawer_open:
				_is_drawer_open = true
				# To avoid tween deadlocks
				# warning-ignore:return_value_discarded
				tween.remove_all()
				# warning-ignore:return_value_discarded
				tween.interpolate_property(
						td,'rect_position', td.rect_position,
						Vector2($Control.rect_size.x,td.rect_position.y),
						0.3, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				# We make all tokens display names
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.expand()
				# Normally the drawer is invisible. We make it visible now
				$Control/Tokens/Drawer.self_modulate[3] = 1
#				 warning-ignore:return_value_discarded
				# warning-ignore:return_value_discarded
				tween.start()
				# We need to make our tokens appear on top of other cards on the table
				$Control/Tokens.z_index = 99
		else:
			if _is_drawer_open:
				# warning-ignore:return_value_discarded
				tween.remove_all()
				# warning-ignore:return_value_discarded
				tween.interpolate_property(
						td,'rect_position', td.rect_position,
						Vector2($Control.rect_size.x - 35,
						td.rect_position.y),
						0.2, Tween.TRANS_ELASTIC, Tween.EASE_IN)
				# warning-ignore:return_value_discarded
				tween.start()
				# We want to consider the drawer closed
				# only when the animation finished
				# Otherwise it might start to open immediately again
				yield(tween, "tween_all_completed")
				# When it's closed, we hide token names
				for token in $Control/Tokens/Drawer/VBoxContainer.get_children():
					token.retract()
				$Control/Tokens/Drawer.self_modulate[3] = 0
				_is_drawer_open = false
				$Control/Tokens.z_index = 0


# Get the angle on the ellipse
func _get_angle_by_index(index_diff = null):
	var index = get_my_card_index()
	var hand_size = get_parent().get_card_count()
	var half
	half = (hand_size - 1) / 2.0
	var card_angle_max: float = 15
	var card_angle_min: float = 5
	# Angle between cards
	var card_angle = max(min(60/hand_size,card_angle_max),card_angle_min)
	# When foucs hand, the card needs to be offset by a certain angle
	# The current practice is just to find a suitable expression function, if there is a better function, please replace this function: - sign(index_diff) * (1.95-0.3*index_diff*index_diff) * min(card_angle,5)
	if index_diff != null:
		return 90 + (half - index) * card_angle \
				- sign(index_diff) * (1.95-0.3*index_diff*index_diff) * min(card_angle,5)
	else:
		return 90 + (half - index) * card_angle


# Get card angle in hand by index that use oval shape
# The angle of the normal on the ellipse
func _get_oval_angle_by_index(
		angle = null,
		index_diff = null,
		hor_rad = null,
		ver_rad = null):
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
	# Oval hor rad, rect_size.x*0.5*1.5 it’s an empirical formula, and it’s tested to feel good
	var hor_rad: float = parent_control.rect_size.x * 0.5 * 1.5
	# Oval ver rad, rect_size.y * 1.5 it’s an empirical formula, and it’s tested to feel good
	var ver_rad: float = parent_control.rect_size.y * 1.5
	# Get the angle from the point on the oval to the center of the oval
	var angle = _get_angle_by_index(index_diff)
	var rad_angle = deg2rad(angle)
	# Get the direction vector of a point on the oval
	var oval_angle_vector = Vector2(hor_rad * cos(rad_angle),
			- ver_rad * sin(rad_angle))
	# Take the center point of the card as the starting point, the coordinates of the top left corner of the card
	var left_top = Vector2(- $Control.rect_size.x/2, - $Control.rect_size.y/2)
	# Place the top center of the card on the oval point
	var center_top = Vector2(0, - $Control.rect_size.y/2)
	# Get the angle of the card, which is different from the oval angle, the card angle is the normal angle of a certain point
	var card_angle = _get_oval_angle_by_index(angle, null, hor_rad,ver_rad)
	# Displacement offset due to card rotation
	var delta_vector = left_top - center_top.rotated(deg2rad(90 - card_angle))
	# Oval center x
	var center_x = parent_control.rect_size.x / 2 + parent_control.rect_position.x
	# Oval center y, - parent_control.rect_size.y * 0.25:This method ensures that the card is moved to the proper position
	var center_y = parent_control.rect_size.y * 1.5 + parent_control.rect_position.y - parent_control.rect_size.y * 0.25
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
				+ Vector2($Control.rect_size.x / index_diff * cfc.NEIGHBOUR_PUSH, 0))
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
