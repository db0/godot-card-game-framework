# The token class is controlling the creation of new tokens
# as well as the control of their counter
class_name Token
extends HBoxContainer


@export var count := 0: 
	get: 	
		var _ret = await get_count_and_alterants()
		return _ret.count
	set(value): set_count(value)
var _count := 0
var token_drawer

@onready var count_label = $CenterContainer/Count

# Called when the node enters the scene tree for the first time.
func _ready():
	set_count(count) # Replace with function body.


# Button to increment token counter by 1
func _on_Add_pressed() -> void:
	set_count(count + 1)


# Button to decrement token counter by 1
func _on_Remove_pressed() -> void:
	set_count(count - 1)
	if count == 0:
		queue_free()


# Initializes the token with the right texture and name 
# based on the values in the configuration
func setup(token_name: String, _token_drawer = null) -> void:
	name = token_name
	token_drawer = _token_drawer
	var textrect : TextureRect = $CenterContainer/TokenIcon
	var tex = load(CFConst.PATH_TOKENS + CFConst.TOKENS_MAP[token_name])
	var image = tex.get_image()
	var new_texture = ImageTexture.create_from_image(image)
	textrect.texture = new_texture
	$Name.text = token_name.capitalize()


# Sets the token counter to the specified value
func set_count(value := 1) -> void:
	# We do not allow tokens to be set to negative values
	if value < 0:
		value = 0
	_count = value
	# Solution taken from
	# https://github.com/godotengine/godot/issues/30460#issuecomment-509697259
	if is_inside_tree():
		count_label.text = str(count)


# Returns the amount of tokens of this type
func get_count() -> int:
	var _ret = await get_count_and_alterants()
	return _ret.count


# Discovers the modified value of this token
# from alterants
#
# Returns a dictionary with the following keys:
# * count: The final value of this token after all modifications
# * alteration: The full dictionary returned by
#	CFScriptUtils.get_altered_value()
func get_count_and_alterants() -> Dictionary:
	var alteration = {
		"value_alteration": 0,
		"alterants_details": {}
	}
	# We do this check because in UT the token might not be
	# assigned to a token_drawer
	if token_drawer:
		alteration = await CFScriptUtils.get_altered_value(
			token_drawer.owner_card,
			"get_token",
			{SP.KEY_TOKEN_NAME: name,},
			_count)
	var return_dict := {
		"count": _count + alteration.value_alteration,
		"alteration": alteration
	}
	return(return_dict)


# Reveals the Name label.
#
# Used when the token drawer is expanded
func expand() -> void:
	$Name.visible = true
	$MarginContainer.visible = true
	$Buttons.visible = true


# Hides the Name label.
#
# Used when the token drawer is withdrawn
func retract() -> void:
	$Name.visible = false
	$MarginContainer.visible = false
	$Buttons.visible = false


# Returns the lowercase name of the token
func get_token_name() -> String:
	return($Name.text.to_lower())
