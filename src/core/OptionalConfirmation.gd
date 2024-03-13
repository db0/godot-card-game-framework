# This scene creates a popup confirmation dialogue
# Which confirms with the player to execute a card script.
extends ConfirmationDialog

signal selected

var is_accepted := false

func _ready() -> void:
	get_cancel_button().text = "No"
	get_ok_button().text = "Yes"
	# warning-ignore:return_value_discarded
	get_cancel_button().connect("pressed", Callable(self, "_on_OptionalConfirmation_cancelled"))


func prep(card_name: String, task_name: String) -> void:
		dialog_text =  card_name + ": Do you want to activate " + task_name + "?"
		cfc.NMAP.board.add_child(self)
		# We spawn the dialogue at the middle of the screen.
		popup_centered()
		# One again we need two different Panels due to 
		# https://github.com/godotengine/godot/issues/32030
		$HorizontalHighlights.size = size
		$HorizontalHighlights.position = Vector2(0,0)
		$VecticalHighlights.size = size
		$VecticalHighlights.position = Vector2(0,0)


func _on_OptionalConfirmation_confirmed() -> void:
	is_accepted = true
	emit_signal("selected")


func _on_OptionalConfirmation_cancelled() -> void:
	is_accepted = false
	emit_signal("selected")

