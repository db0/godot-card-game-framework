# A card title which includes a display of the card when hovered
class_name CardLabel
extends RichTextLabel

onready var preview_popup := $PreviewPopup

func _ready() -> void:
	text = "Test Card 1" # debug

func setup(card_name) -> void:
	bbcode_text = card_name


func _on_CardLabel_mouse_entered() -> void:
	preview_popup.show_preview_card(text)


func _on_CardLabel_mouse_exited() -> void:
	preview_popup.hide_preview_card()
