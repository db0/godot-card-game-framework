# This script handles interactions with the token drawr on a Card.
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Drawer/Area2D/CollisionShape2D.shape = \
			$Drawer/Area2D/CollisionShape2D.shape.duplicate()


func _process(_delta: float) -> void:
	# Every process tick, it will ensure the collsion shape for the
	# drawer is adjusted to its current size
	$Drawer/Area2D.position = $Drawer.rect_size/2
	var shape: RectangleShape2D = $Drawer/Area2D/CollisionShape2D.shape
	# We're extending the area of the drawer a bit, to try and avoid it
	# glitching when moving from card to drawer and back
	shape.extents = $Drawer.rect_size/2 + Vector2(10,0)


# Returns true, when the mouse cursor is over the drawer.
# This is used to retain focus on the card
# while the player is manipulating tokens.
func _is_hovered() -> bool:
	var is_hovered = false
	if cfc.NMAP.board.mouse_pointer in $Drawer/Area2D.get_overlapping_areas():
		is_hovered = true
	return(is_hovered)
