extends VBoxContainer

func _process(_delta: float) -> void:
	# We count how many cards of this type we have
	# and adjust the number in the label
	# If there are ever no more cards in this category
	# we deinstance it.
	var category_card_count = 0
	for deck_card_object in $CategoryCards.get_children():
		category_card_count += deck_card_object.quantity
	if category_card_count == 0:
		queue_free()
	else:
		$CategoryLabel.text = name + ' (' + str(category_card_count) + ')'
