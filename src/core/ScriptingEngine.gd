class_name ScriptingEngine
extends Reference

var running_scripts: Array
var card_owner
var target_card = null
# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(owner, target) -> void:
	card_owner = owner
	
func run_next_script() -> void:
	if running_scripts.empty():
		print('Scripting: All done!') # Debug
	else:
		var script = running_scripts.pop_front()
		print("Scripting: " + str(script)) # Debug
		if script['name'] == 'custom':
			call('custom_script')
		elif script['name']:
			call(script['name'], script['args']) # Args should be an array of arguments to pass
			""" Available scripts:
				move_to_container([Card, CardContainer])
				move_self_to_board([Card, Vector2])
				generate_card([str card_path, int amount])
				rotate_card([Card, int degrees])
			"""
		else:
			print("[WARN] Found empty script. Ignoring...")
			script_succeeded() # If card has a script but it's null, it probably not coded yet. Just go on...

func script_succeeded() -> void:
	# Monitors if one of the card effect scripts has succeeded and if it has, checks if there's more to do in the stack
	run_next_script()

# warning-ignore:unused_argument
func rotate_self(args) -> void:
	var degrees: int = args[1]
	rotate_card([card_owner,  args[1]])
	
# warning-ignore:unused_argument
func rotate_card(args) -> void:
	var card = args[0]
	var degrees: int = args[1]
	card_owner.card_rotation = degrees
	yield(card.get_node("Tween"), "tween_all_completed")
	run_next_script()
	
# warning-ignore:unused_argument
func move_self_to_container(args) -> void:
	var container = args[1]
	move_card_to_container([card_owner,container])
	
# warning-ignore:unused_argument
func move_card_to_container(args) -> void:
	var card = args[0]
	var container = args[1]
	card.move_to(container)
	yield(card.get_node("Tween"), "tween_all_completed")
	if cfc.fancy_movement:
		yield(card.get_node("Tween"), "tween_all_completed")
	run_next_script()
