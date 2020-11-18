extends Pile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", cfc.NMAP.hand, "_on_Deck_input_event")
	#print(get_signal_connection_list("input_event")[0]['target'].name)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

