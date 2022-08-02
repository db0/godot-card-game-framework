extends CardFront

func _ready() -> void:
	_card_text = find_node("CardText")
	# Map your card text label layout here. We use this when scaling
	# The card or filling up its text
	card_labels["Name"] = find_node("Name")
	card_labels["Type"] = find_node("Type")
	card_labels["Tags"] = find_node("Tags")
	card_labels["Requirements"] = find_node("Requirements")
	card_labels["Abilities"] = find_node("Abilities")
	card_labels["Cost"] = find_node("Cost")
	card_labels["Power"] = find_node("Power")

	# These set te max size of each label. This is used to calculate how much
	# To shrink the font when it doesn't fit in the rect.
	card_label_min_sizes["Name"] = Vector2(CFConst.CARD_SIZE.x - 4, 30)
	card_label_min_sizes["Type"] = Vector2(CFConst.CARD_SIZE.x - 4, 26)
	card_label_min_sizes["Tags"] = Vector2(CFConst.CARD_SIZE.x - 4, 34)
	card_label_min_sizes["Requirements"] = Vector2(CFConst.CARD_SIZE.x - 4, 24)
	card_label_min_sizes["Abilities"] = Vector2(CFConst.CARD_SIZE.x - 4, 240)
	card_label_min_sizes["Cost"] = Vector2(15,30)
	card_label_min_sizes["Power"] = Vector2(15,30)

	# This is not strictly necessary, but it allows us to change
	# the card label sizes without editing the scene
	for l in card_label_min_sizes:
		card_labels[l].rect_min_size = card_label_min_sizes[l]

	# This stores the maximum size for each label, when the card is at its
	# standard size.
	# This is multiplied when the card is resized in the viewport.
	for label in card_labels:
		match label:
			"Cost","Power":
				original_font_sizes[label] = 30
			"Requirements":
				original_font_sizes[label] = 22
			"Abilities":
				original_font_sizes[label] = 50
			_:
				original_font_sizes[label] = 32
				
