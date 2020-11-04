extends Node2D
class_name CardContainer


var dropping_card: Card = null
var catching_card: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_entered", self, "_on_mouse_entered")
	# warning-ignore:return_value_discarded
	$Control.connect("mouse_exited", self, "_on_mouse_exited")
	#print('a',self.get_node('HostedCards'), self.name)

func _on_dropped_card(card: Card) -> void:
	# This signal will arrive before the engine knows over which control our mouse pointer is
	# Therefore we cannot set the "catcher control" with the _on_mouse_enterred() signal
	# Instead we simply set a variable for the card and wait to see if the
	# catching_card variable will also be set immediately afterwards
	# Note: This variable will be set on all  such containers, so will need to be cleared if not used. We do that in _process.
	dropping_card = card


func _process(_delta):
	# Here we check if both switches have been set, which would signify this is the container which catches the dropped card
	if dropping_card and catching_card: 
		dropping_card.reHost(self)
	else:
		# If the dropping card is not in a state 'Dragged' anymore, it means another container has picked it up already
		# So we clear our hook.
		if dropping_card and dropping_card.state != 5:  # state 5 == 'Dragged'
			dropping_card = null

func _on_mouse_entered() -> void:
	# Unfortunately the gui inputs will not be sent to this control
	# Until the card is dropped, so we will only know the mouse has enterred this container 
	# only AFTER the card_cropped signal has been sent
	# Therefore we set a switch here and then compare every frame until it's cleared
	catching_card = true
	
func _on_mouse_exited() -> void:
	catching_card = false

func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		if obj as Card: cardsArray.append(obj)
	return cardsArray

func get_card_count() -> int:
	return len(get_all_cards())

func get_card(idx: int) -> Card:
	return get_all_cards()[idx]
