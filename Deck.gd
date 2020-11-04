extends  CardContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", cfc_config.NMAP.hand, "_on_Deck_gui_input")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
