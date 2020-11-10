extends  CardContainer
class_name Pile

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Control/ManipulationButtons/View.connect("pressed",self,'_on_View_Button_pressed')
	$Control/ManipulationButtons/Shuffle.connect("pressed",self,'_on_Shuffle_Button_pressed')


func _on_View_Button_pressed():
	print($Control/ManipulationButtons/View.name)

func _on_Shuffle_Button_pressed():
	print($Control/ManipulationButtons/Shuffle.name)
	var cardsArray := []
	for card in get_all_cards():
		cardsArray.append(card)
	randomize()
	cardsArray.shuffle()
	for card in cardsArray:
		move_child(card,cardsArray.find(card))
