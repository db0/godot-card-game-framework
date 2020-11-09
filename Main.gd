extends Node2D

var focused_object = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#$Focus/Viewport.world_2d = $ViewportContainer/Viewport.world_2d
	#$Focus/Viewport/Camera2D.position = $ViewportContainer/Viewport/Board/Deck.position

func focus_card(card: Card):
	$Focus.visible = true
	focused_object.append(card.duplicate())
	$Focus/Viewport.add_child(focused_object[0])
	focused_object[0].scale = Vector2(1.5,1.5)
	$Focus/Viewport/Camera2D.position = focused_object[0].global_position
	if not $Focus/Tween.is_active(): # We only want to do something if we're actually doing something
		$Focus/Tween.remove_all()
		$Focus/Tween.interpolate_property($Focus,'modulate',
		Color(1,1,1,0), Color(1,1,1,1), 0.25,
		Tween.TRANS_SINE, Tween.EASE_IN)
		$Focus/Tween.start()

func unfocus():
	if not $Focus/Tween.is_active(): # We only want to do something if we're actually doing something
		$Focus/Tween.remove_all()
		$Focus/Tween.interpolate_property($Focus,'modulate',
		Color(1,1,1,1), Color(1,1,1,0), 0.25,
		Tween.TRANS_SINE, Tween.EASE_IN)
	$Focus/Tween.start()
	yield($Focus/Tween, "tween_all_completed")
	$Focus.visible = false
	for c in focused_object:
		focused_object.erase(c)
		c.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#	if fmod(delta,2) < 1: print($Focus.modulate)
