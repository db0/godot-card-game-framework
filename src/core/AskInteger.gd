# Pops up a dialogie for the player to enter an integer.
# Typically called by a card script that needs that player
# to provide a value
extends AcceptDialog

var minimum: int
var maximum: int
var number: int
var leading_zeroes_regex := RegEx.new()


func _ready() -> void:
	# warning-ignore:return_value_discarded
	leading_zeroes_regex.compile("^0+([1-9]+)")
	get_ok().text = "Submit"


# Prepares the window to request the integer from the player
# in the correct range and bring the popup to the front.
func prep(title_reference: String, min_req: int, max_req : int) -> void:
		window_title = "Please enter number for the effect of " + title_reference
		$LineEdit.placeholder_text = \
				"Enter number between " + str(min_req) + " and " + str(max_req)
		minimum = min_req
		maximum = max_req
		#$LineEdit.text = str(minimum)
		cfc.NMAP.board.add_child(self)
		popup_centered()
		# One again we need two different Panels due to
		# https://github.com/godotengine/godot/issues/32030
		# Adjustments below are to make the highlight fit over the whole window
		# including its decoration.
		var highlight_offset = Vector2(8, 27)
		$HorizontalHighlights.rect_size = rect_size + highlight_offset
		$VecticalHighlights.rect_size = rect_size + highlight_offset
		$HorizontalHighlights.rect_position = -highlight_offset + Vector2(3.5, 3.5)
		$VecticalHighlights.rect_position = -highlight_offset + Vector2(3.5, 3.5)
		_switch_red()
		#print($HorizontalHighlights.rect_size)
		# We spawn the dialogue at the middle of the screen.


func _on_LineEdit_text_entered(new_text: String) -> void:
	if new_text.is_valid_integer() and \
			int(new_text) >= minimum \
			and int(new_text) <= maximum:
		number = int(new_text)
		hide()


func _switch_red() -> void:
	$HorizontalHighlights.modulate = Color(1.4,0,0)
	$VecticalHighlights.modulate = Color(1.2,0,0)

func _switch_green() -> void:
	$HorizontalHighlights.modulate = Color(0,1.6,0)
	$VecticalHighlights.modulate = Color(0,1.4,0)

func _on_LineEdit_text_changed(new_text: String) -> void:
	var leading_zeroes = leading_zeroes_regex.search(new_text)
	if leading_zeroes:
		$LineEdit.text = leading_zeroes.get_string(1)
	if not new_text.is_valid_integer() or \
			int(new_text) < minimum \
			or int(new_text) > maximum:
		_switch_red()
	else:
		_switch_green()


func _on_AskInteger_confirmed() -> void:
	_on_LineEdit_text_entered($LineEdit.text)
