# Handles drawing an Object's (primarily a card's) targeting arrow
# and specifying the final target
class_name TargetingArrow
extends Line2D

# Emitted whenever the object spawns a targeting arrow.
signal initiated_targeting
# Emitted whenever the object has selected a target.
signal target_selected(target)
# Emitted whenever the target arrow hovers over a valid target.
signal potential_target_found(target)
# We use this to track multiple potential target objects
# when our owner_card is about to target them.
var _potential_targets := []
# If true, the targeting arrow will be drawn towards the mouse cursor
var is_targeting := false
# Used to store a card succesfully targeted.
# It should be cleared from whichever effect requires a target.
# once it is used
var target_object : Node = null
# Stores a reference to the Card that is hosting this node
onready var owner_object = get_parent()


func _ready() -> void:
	# We set the targetting arrow modulation to match our config specification
	default_color = CFConst.TARGETTING_ARROW_COLOUR
	$ArrowHead.color = CFConst.TARGETTING_ARROW_COLOUR
	# warning-ignore:return_value_discarded
	$ArrowHead/Area2D.connect("area_entered", self, "_on_ArrowHead_area_entered")
	# warning-ignore:return_value_discarded
	$ArrowHead/Area2D.connect("area_exited", self, "_on_ArrowHead_area_exited")


func _process(_delta: float) -> void:
	if is_targeting:
		_draw_targeting_arrow()


# Will generate a targeting arrow on the card which will follow the mouse cursor.
# The top card hovered over by the mouse cursor will be highlighted
# and will become the target when complete_targeting() is called
func initiate_targeting() -> void:
	is_targeting = true
	$ArrowHead.visible = true
	$ArrowHead/Area2D.monitoring = true
	emit_signal("initiated_targeting")


# Will end the targeting process.
#
# The top targetable object which is hovered (if any) will become the target and inserted
# into the target_object property for future use.
func complete_targeting() -> void:
	if len(_potential_targets) and is_targeting:
		var tc = _potential_targets.back()
		# We don't want to emit a signal, if the card is a dummy viewport card
		# or we already selected a target during dry-run
		if owner_object.get_parent() != null \
				and owner_object.get_parent().name != "Viewport":
			# We make the targeted card also emit a targeting signal for automation
			tc.emit_signal("card_targeted", tc, "card_targeted",
					{"targeting_source": owner_object})
		target_object = tc
	emit_signal("target_selected",target_object)
	is_targeting = false
	clear_points()
	$ArrowHead.visible = false
	$ArrowHead/Area2D.monitoring = false


# Triggers when a targetting arrow hovers over another card while being dragged
#
# It takes care to highlight potential cards which can serve as targets.
func _on_ArrowHead_area_entered(area: Area2D) -> void:
	if area.get_class() == 'Card' and not area in _potential_targets:
		_potential_targets.append(area)
		if 'highlight' in owner_object:
			owner_object.highlight.highlight_potential_card(
					CFConst.TARGET_HOVER_COLOUR, _potential_targets)
		emit_signal("potential_target_found", area)


# Triggers when a targetting arrow stops hovering over a card
#
# It clears potential highlights and adjusts potential cards as targets
func _on_ArrowHead_area_exited(area: Area2D) -> void:
	if area.get_class() == 'Card' and area in _potential_targets:
		# We remove the card we stopped hovering from the _potential_targets
		_potential_targets.erase(area)
		# And we explicitly hide its cards focus since we don't care about it anymore
		if 'highlight' in area:
			area.highlight.set_highlight(false)
		# Finally, we make sure we highlight any other cards we're still hovering
		if not _potential_targets.empty() and 'highlight' in owner_object:
			owner_object.highlight.highlight_potential_card(
				CFConst.TARGET_HOVER_COLOUR,
				_potential_targets)


# Draws a curved arrow, from the center of a card, to the mouse pointer
func _draw_targeting_arrow() -> void:
	# This variable calculates the card center's position on the whole board
	var card_half_size
	if "rect_size" in owner_object:
		card_half_size = owner_object.rect_size/2
	else: 
		card_half_size = owner_object.card_size/2
	var centerpos = global_position + card_half_size * scale
	# We want the line to be drawn anew every frame
	clear_points()
	# The final position is the mouse position,
	# but we offset it by the position of the card center on the map
	var final_point =  cfc.NMAP.board.mouse_pointer.determine_global_mouse_pos() \
			- (position + card_half_size)
	var curve = Curve2D.new()
#		var middle_point = centerpos + (get_global_mouse_position() - centerpos)/2
#		var middle_dir_to_vpcenter = middle_point.direction_to(get_viewport().size/2)
#		var offmid = middle_point + middle_dir_to_vpcenter * 50
	# Our starting point has to be translated to the local position of the Line2D node
	# The out control point is the direction to the screen center,
	# with a magnitude that I found via trial and error to look good
	curve.add_point(to_local(centerpos),
			Vector2(0,0),
			centerpos.direction_to(get_viewport().size/2) * 75)
#		curve.add_point($TargetLine.to_local(offmid), Vector2(0,0), Vector2(0,0))
	# Our end point also has to be translated to the local position of the Line2D node
	# The in control point is likewise the direction to the screen center
	# with a magnitude that I found via trial and error to look good
	curve.add_point(to_local(position +
			card_half_size + final_point),
			Vector2(0, 0), Vector2(0, 0))
	# Finally we use the Curve2D object to get the points which will be drawn
	# by our lined2D
	set_points(curve.get_baked_points())
	# We place the arrowhead to start from the last point in the line2D
	$ArrowHead.position = get_point_position(
			get_point_count( ) - 1)
	# We delete the last 3 Line2D points, because the arrowhead will
	# be covering those areas
	for _del in range(1,3):
		remove_point(get_point_count( ) - 1)
	# We setup the angle the arrowhead is pointing by finding the angle of
	# the last point on the line towards the mouse position
	$ArrowHead.rotation = get_point_position(
				get_point_count( ) - 1).direction_to(
				to_local(position + card_half_size + final_point)).angle()
