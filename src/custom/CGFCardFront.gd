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
	card_labels["Name"] = $Margin/CardText/Name
	card_labels["Type"] = $Margin/CardText/Type
	card_labels["Tags"] = $Margin/CardText/Tags
	card_labels["Requirements"] = $Margin/CardText/Requirements
	card_labels["Abilities"] = $Margin/CardText/Abilities
	card_labels["Cost"] = $Margin/CardText/HB/Cost
	card_labels["Power"] = $Margin/CardText/HB/Power
