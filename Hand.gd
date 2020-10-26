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
		if  get_child_count() < hand_size:
			var card = container.pop_front().instance()
			card.moveToContainer(Vector2(0,0),get_viewport().size / 2)
			#card.rect_position = get_viewport().size / 2
			#card.rect_position.y = get_viewport().size.y - card.rect_size.y
			add_child(card)
			#host_card(container.pop_front().instance())

#func host_card(card) -> void:
#	hand_contents.append(card)
	#realign_cards()
#
#func realign_cards() -> void:
#	if len(hand_contents) > 4:
#		var too_many_cards_separation := separation_step * (len(hand_contents))
#		if too_many_cards_separation < maximum_separation: too_many_cards_separation = maximum_separation
#		$HBoxContainer/HandArray.set("custom_constants/separation", too_many_cards_separation)
#	else:
#		$HBoxContainer/HandArray.set("custom_constants/separation", 0)
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
