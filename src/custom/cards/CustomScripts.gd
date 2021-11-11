# This class contains very custom scripts definitionsa for objects that need them
#
# The definition happens via object name
class_name CustomScripts
extends Reference

var costs_dry_run := false

func _init(_dry_run) -> void:
	costs_dry_run = _dry_run
# This fuction executes custom scripts
#
# It relies on the definition of each script being based the object's name
# Therefore the only thing we need, is the object itself to grab its name
# And to have a self-reference in case it affects itself
#
# You can pass a predefined subject, but it's optional.
func custom_script(script: ScriptTask) -> void:
	var card: Card = script.owner
	var subjects: Array = script.subjects
	# I don't like the extra indent caused by this if, 
	# But not all object will be Card
	# So I can't be certain the "canonical_name" var will exist
	match script.owner.canonical_name:
		"Test Card 2":
			# No demo cost-based custom scripts
			if not costs_dry_run:
				print("This is a custom script execution.")
				print("Look! I am going to destroy myself now!")
				card.queue_free()
				print("You can do whatever you want here.")
		"Test Card 3":
			if not costs_dry_run:
				print("This custom script uses the _find_subject()"
						+ " to find a convenient target")
				for subject in subjects:
					subjects[0].queue_free()
					print("Destroying: " + subjects[0].canonical_name)

# warning-ignore:unused_argument
func custom_alterants(script: ScriptAlter) -> int:
	var alteration := 0
	return(alteration)
