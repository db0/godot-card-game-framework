extends Hand


func _ready() -> void:
	super._ready()
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/DiscardRandom.connect("pressed", Callable(self, '_on_DiscardRandom_Button_pressed'))

