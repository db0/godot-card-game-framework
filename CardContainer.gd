extends Area2D
class_name CardContainer


var waiting_for_card_drop: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_entered", self, "_on_mouse_entered")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_exited", self, "_on_mouse_exited")

func get_class(): return "CardContainer"

func _on_mouse_entered():
	waiting_for_card_drop = true
#	print('Enter: ', self.name)

func _on_mouse_exited():
	waiting_for_card_drop = false
#	print('Exit: ', self.name)

func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		if obj as Card: cardsArray.append(obj)
	return cardsArray

func get_card_count() -> int:
	return len(get_all_cards())

func get_card(idx: int) -> Card:
	return get_all_cards()[idx]

func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)

#func _input(event):
	#if event is InputEventMouseButton: 
		#print(event.position)
