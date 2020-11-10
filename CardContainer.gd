extends Area2D
class_name CardContainer

var waiting_for_card_drop: bool = false

func get_class(): return "CardContainer"

func _ready() -> void:
	$Control/ManipulationButtons.connect("mouse_entered",self,"_on_ManipulationButtons_mouse_entered")
	$Control/ManipulationButtons.connect("mouse_exited",self,"_on_ManipulationButtons_mouse_exited")


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


func _on_ManipulationButtons_mouse_entered():
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,1), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()

func _on_ManipulationButtons_mouse_exited():
	$Control/ManipulationButtons/Tween.remove_all() # We always make sure to clean tweening conflicts
	$Control/ManipulationButtons/Tween.interpolate_property($Control/ManipulationButtons,'modulate',
	$Control/ManipulationButtons.modulate, Color(1,1,1,0), 0.25,
	Tween.TRANS_SINE, Tween.EASE_IN)
	$Control/ManipulationButtons/Tween.start()


