class_name CardLabel
extends Label

var preview_card: Card
onready var preview_popup:= $PreviewPopup
onready var focus_panel := $PreviewPopup/FocusInfoPanel
onready var illustration := $PreviewPopup/FocusInfoPanel/VBC/Illustration

func _ready() -> void:
	text = "Test Card 1" # debug

func _process(_delta: float) -> void:
	if preview_popup.visible:
		preview_popup.rect_position = get_preview_placement()
		# This ensures the FocusInfoPanel is always on the bottom of the card
		focus_panel.rect_size.x = CFConst.CARD_SIZE.x * preview_card.scale.x
		focus_panel.rect_position.y = CFConst.CARD_SIZE.y * preview_card.scale.y


func setup(card_name) -> void:
	text = card_name

func _on_CardLabel_mouse_entered() -> void:
	preview_card = cfc.instance_card(text)
	preview_popup.rect_position = get_preview_placement()
	preview_popup.add_child(preview_card)
	var card_illustration = preview_card.get_property("_illustration")
	if card_illustration:
		illustration.text = "Illustration by: " + card_illustration
		focus_panel.visible = true
	else:
		focus_panel.visible = false
	preview_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_popup.visible = true


func _on_CardLabel_mouse_exited() -> void:
	preview_card.queue_free()
	preview_popup.visible = false

func get_preview_placement() -> Vector2:
	var ret : Vector2
	var focus_panel_offset = 0
	if focus_panel.visible:
		focus_panel_offset = focus_panel.rect_size.y
	if get_global_mouse_position().y\
			+ CFConst.CARD_SIZE.y * preview_card.scale.y\
			+ focus_panel_offset\
			> get_viewport().size.y:
		ret = Vector2(get_global_mouse_position().x + 10,
				get_viewport().size.y\
				- CFConst.CARD_SIZE.y\
				* preview_card.scale.y\
				- focus_panel_offset)
	else:
		ret = get_global_mouse_position() + Vector2(10,0)
	return(ret)
