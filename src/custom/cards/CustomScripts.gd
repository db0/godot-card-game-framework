# This class contains very custom scripts definitionsa for objects that need them
#
# The definition happens via object name
class_name CustomScripts
extends Reference


# This fuction executes custom scripts
#
# It relies on the definition of each script being based the object's name
# Therefore the only thing we need, is the object itself to grab its name
# And to have a self-reference in case it affects itself
#
# You can pass a predefined subject, but it's optional.
func custom_script(object, subject = null) -> void:
	# I don't like the extra indent caused by this if, 
	# But not all object will be Card
	# So I can't be certain the "card_name" var will exist
	if object.get_class() == "Card":
		match object.card_name:
			"Test Card 2":
				print("This is a custom script execution.")
				print("Look! I am going to destroy myself now!")
				object.queue_free()
				print("You can do whatever you want here.")
			"Test Card 3":
				print("This custom script uses the _find_subject()"
						+ " to find a convenient target")
				print("Destroying: " + subject.card_name)
				subject.queue_free()
