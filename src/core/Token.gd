# The token class is controlling the creation of new tokens
# as well as the control of their counter
class_name Token
extends HBoxContainer


export var count := 1 setget set_count, get_count

onready var count_label = $CenterContainer/Count

# Called when the node enters the scene tree for the first time.
func _ready():
	set_count(count) # Replace with function body.


# Initializes the token with the right texture and name 
# based on the values in the configuration
func setup(token_name: String) -> void:
	name = token_name
	var textrect : TextureRect = $CenterContainer/TokenIcon
	var new_texture = ImageTexture.new();
	var tex = load(cfc.token_assets_path + cfc.tokens_map[token_name])
	var image = tex.get_data()
	new_texture.create_from_image(image)
	textrect.texture = new_texture
	$Name.text = token_name.capitalize()


# Sets the token counter to the specified value
func set_count(value := 1) -> void:
	if value < 0:
		value = 0
	count = value
	# Solution taken from
	# https://github.com/godotengine/godot/issues/30460#issuecomment-509697259
	if is_inside_tree():
		count_label.text = str(count)


# Returns the amount of tokens of this type
func get_count() -> int:
	return count


# Reveals the Name label.
#
# Used when the token drawer is expanded
func expand() -> void:
	$Name.visible = true
	$MarginContainer.visible = true


# Hides the Name label.
#
# Used when the token drawer is withdrawn
func retract() -> void:
	$Name.visible = false
	$MarginContainer.visible = false


func adjust_to_rot(degrees: int) -> void:
	rect_rotation = -degrees
