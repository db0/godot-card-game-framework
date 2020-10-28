extends Node2D

var deck := [] # A pseudo-deck array to hold the card objects we want to pull
const cardTemplate = preload("res://CardTemplate.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(20):
		deck.append(cardTemplate)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
