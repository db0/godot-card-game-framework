extends Panel
class_name CardContainer

var waiting_for_hosting: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "_on_mouse_entered")
	# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "_on_mouse_exited")

func _on_dropped_card(card) -> void:
	if waiting_for_hosting: 
		print('a')
		card.reHost(self)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_mouse_entered() -> void:
	waiting_for_hosting = true
	#print(waiting_for_hosting)
	
func _on_mouse_exited() -> void:
	waiting_for_hosting = false
	#print(waiting_for_hosting)
