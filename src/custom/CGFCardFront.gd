extends CardFront

func _ready() -> void:
	text_expansion_multiplier = {
		"Name": 2,
		"Tags": 1.2,
		"Cost": 3,
		"Power": 3,
	}
	compensation_label = "Abilities"
	_card_text = $Margin/CardText
	# Map your card text label layout here. We use this when scaling
	# The card or filling up its text
	card_labels["Name"] = $Margin/CardText/Name
	card_labels["Type"] = $Margin/CardText/Type
	card_labels["Tags"] = $Margin/CardText/Tags
	card_labels["Requirements"] = $Margin/CardText/Requirements
	card_labels["Abilities"] = $Margin/CardText/Abilities
	card_labels["Cost"] = $Margin/CardText/HB/Cost
	card_labels["Power"] = $Margin/CardText/HB/Power

	# These set te max size of each label. This is used to calculate how much
	# To shrink the font when it doesn't fit in the rect.
	card_label_min_sizes["Name"] = Vector2(CFConst.CARD_SIZE.x - 4, 19)
	card_label_min_sizes["Type"] = Vector2(CFConst.CARD_SIZE.x - 4, 13)
	card_label_min_sizes["Tags"] = Vector2(CFConst.CARD_SIZE.x - 4, 17)
	card_label_min_sizes["Requirements"] = Vector2(CFConst.CARD_SIZE.x - 4, 11)
	card_label_min_sizes["Abilities"] = Vector2(CFConst.CARD_SIZE.x - 4, 144)
	card_label_min_sizes["Cost"] = Vector2(40,13)
	card_label_min_sizes["Power"] = Vector2(40,13)

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
				original_font_sizes[label] = 10
			"Requirements":
				original_font_sizes[label] = 11
			_:
				original_font_sizes[label] = 16
