class_name Token
extends HBoxContainer



export var count := 1 setget set_count, get_count

onready var count_label = $CenterContainer/Count

# Called when the node enters the scene tree for the first time.
func _ready():
	set_count(count) # Replace with function body.

func setup(token_name: String) -> void:
	name = token_name
	var textrect : TextureRect = $CenterContainer/TokenIcon
	var new_texture = ImageTexture.new();
	var tex = load("res://assets/tokens/%s.svg" % cfc.tokens_map[token_name])
	var image = tex.get_data()
	new_texture.create_from_image(image)
	textrect.texture = new_texture
	$Name.text = token_name.capitalize()
	
func set_count(value := 1) -> void:
	if value < 0:
		value = 0
	count = value
	# Solution taken from 
	# https://github.com/godotengine/godot/issues/30460#issuecomment-509697259
	if is_inside_tree():
		count_label.text = str(count)
	
func get_count() -> int:
	return count


func expand() -> void:
	$Name.visible = true
	$MarginContainer.visible = true

func retract() -> void:
	$Name.visible = false
	$MarginContainer.visible = false
