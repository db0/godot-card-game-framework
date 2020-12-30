extends Hand


func _ready() -> void:
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/DiscardRandom.connect("pressed",self,'_on_DiscardRandom_Button_pressed')

