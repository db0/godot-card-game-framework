extends Node2D

var hand_size := 12

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

#func _on_GetCard_pressed() -> void:
#	if not deck.empty():
#		draw_card(deck)

func draw_card(container = $'../'.deck) -> void:
		# A basic function to pull a card from out deck into our hand.
		if  get_child_count() < hand_size: # prevent from drawing more cards than are in our deck and crashing godot.
			var card = container.pop_front().instance() # pop() removes a card from its container as well.
			add_child(card)
			card.moveToPosition(Vector2(0,0),card.recalculatePosition())
			for c in get_children():
				if c != card:
					c.interruptTweening()
					c.reorganizeSelf()

#func host_card(card) -> void:
#	hand_contents.append(card)
	#realign_cards()
#
#func discard(card) -> void:
#	card.get_parent().remove_child(card)
#	$HBoxContainer/Discard.add_child(card)
#	realign_cards()
#
#func list_files_in_directory(path) -> Array:
#	var files := []
#	var dir := Directory.new()
#	dir.open(path)
#	dir.list_dir_begin()
#	while true:
#		var file := dir.get_next()
#		if file == "":
#			break
#		elif not file.begins_with("."):
#			files.append(file)
#	dir.list_dir_end()
#	return files

func _on_Button_pressed():
	draw_card() # Replace with function body.
