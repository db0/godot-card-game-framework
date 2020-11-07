extends  CardContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	connect("input_event", cfc_config.NMAP.hand, "_on_Deck_input_event")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
