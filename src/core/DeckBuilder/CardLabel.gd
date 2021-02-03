class_name CardLabel
extends Label

var preview_card: Card
onready var preview_popup:= $PreviewPopup

func _ready() -> void:
	text = "Test Card 1" # debug

func _process(_delta: float) -> void:
	if preview_popup.visible:
		preview_popup.rect_position = get_preview_placement()

func setup(card_name) -> void:
	text = card_name

func _on_CardLabel_mouse_entered() -> void:
	preview_card = cfc.instance_card(text)
	preview_popup.rect_position = get_preview_placement()
	preview_popup.add_child(preview_card)
	preview_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_popup.visible = true


func _on_CardLabel_mouse_exited() -> void:
	preview_card.queue_free()
	preview_popup.visible = false

func get_preview_placement() -> Vector2:
	var ret : Vector2
	if get_global_mouse_position().y\
			+ CFConst.CARD_SIZE.y * preview_card.scale.y\
			> get_viewport().size.y:
		ret = Vector2(get_global_mouse_position().x + 10, get_viewport().size.y
				- CFConst.CARD_SIZE.y * preview_card.scale.y )
	else:
		ret = get_global_mouse_position() + Vector2(10,0)
	return(ret)
