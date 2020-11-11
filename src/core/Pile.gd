extends  CardContainer
class_name Pile

# Called when the node enters the scene tree for the first time.
func _ready():
	# warning-ignore:return_value_discarded
	$Control/ManipulationButtons/View.connect("pressed",self,'_on_View_Button_pressed')
	# warning-ignore:return_value_discarded
	$ViewPopup.connect("popup_hide",self,'_on_ViewPopup_popup_hide')
	$ViewPopup.connect("about_to_show",self,'_on_ViewPopup_about_to_show')


func _on_View_Button_pressed() -> void:
	# This populates our pop-up window with all the cards in the deck
	# Then displays it
	# We set the size of the grid to hold slightly scaled-down cards
	for card in get_all_cards(false):
		# We remove the card to rehost it in the popup grid container
		remove_child(card)
		_slot_card_into_popup(card)
	# Finally we Pop the Up :)
	$ViewPopup.popup_centered()


func _on_ViewPopup_about_to_show() -> void:
	if not $ViewPopup/Tween.is_active():
		$ViewPopup/Tween.interpolate_property($ViewPopup,'modulate',
			Color(1,1,1,0), Color(1,1,1,1), 0.5,
			Tween.TRANS_EXPO, Tween.EASE_IN)
		$ViewPopup/Tween.start()

func _on_ViewPopup_popup_hide() -> void:
	# This function makes sure to return all card objects to the root node once the pop-up closes
	$ViewPopup/Tween.remove_all()
#		$Tween.interpolate_property($ViewPopup,'rect_size:x',
#			0, $ViewPopup.rect_size.x, 0.5,
#			Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$ViewPopup/Tween.interpolate_property($ViewPopup,'modulate',
		Color(1,1,1,1), Color(1,1,1,0), 0.5,
		Tween.TRANS_EXPO, Tween.EASE_OUT)
	$ViewPopup/Tween.start()
	yield($ViewPopup/Tween, "tween_all_completed")
	for card in get_all_cards():
		# For each card we have hosted, we check if it's hosted in the popup. If it is, we move it to the root.
		if "CardPopUpSlot" in card.get_parent().name:
			card.get_parent().remove_child(card)
			add_child(card)
			# We need to remember that cards in piles should be left invisible and at default scale
			card.scale = Vector2(1,1)
			card.modulate[3] = 0

func _process(_delta) -> void:
	# This performs a bit of garbage collection to make sure no Control temp objects
	# are leftover empty in the popup
	for obj in $ViewPopup/CardView.get_children():
		if not obj.get_child_count():
			obj.queue_free()
		# This is needed for the instance where a player tries to drag a card from the gid
		# to the same CardContainer
		elif obj.get_child(0).modulate[3] != 1:
				obj.get_child(0).modulate[3] = 1
				obj.get_child(0).scale = Vector2(0.75,0.75)
	# We make sure to adjust our popup if cards were removed from it while it's open
	$ViewPopup.set_as_minsize()

func add_child(node, _legible_unique_name=false) -> void:
	# We override the built-in add_child() method
	# because we want to do more stuff depending if the object is a Card
	if not $ViewPopup.visible:
		.add_child(node)
		if node as Card:
			# By raising the $Control every time a card is added
			# we ensure it's always drawn on top of the card objects
			$Control.raise()
	elif node as Card: # This triggers if the ViewPopup node is active
		# When the player adds card while the viewpopup is active
		# we move them automatically to the viewpopup grid.
		_slot_card_into_popup(node)

func _slot_card_into_popup(card) -> void:
	# This function prepares the card to be added to the popup grid
	# We need to make the cards visible as they're by default invisible in piles
	card.modulate[3] = 1
	# We also scale-down the cards to be able to see more at the same time.
	# We need to do it before we add the card object to the control temp, otherwise it will default to the pre-scaled size
	card.scale = Vector2(0.75,0.75)
	# The grid container will only grid control objects
	# and the card nodes have an Area2D as a root
	# Therefore we instantatiate a new Control container to put the card objects in
	var card_slot := Control.new()
	card_slot.set_name("CardPopUpSlot")
	# We set the control container its size to be equal to the card size the card will scale to
	card_slot.rect_min_size = card.get_node("Control").rect_min_size * card.scale
	$ViewPopup/CardView.add_child(card_slot)
	# Finally, the card is added to the temporary control node parent.
	card_slot.add_child(card)

func get_all_cards(scanViewPopup := true) -> Array:
	var cardsArray := .get_all_cards()
	# For piles, we need to check if the card objects are inside the ViewPopup.
	if not len(cardsArray) and scanViewPopup:
		if $ViewPopup/CardView.get_child_count():
			# We know it's not possible to have a temp control container (due to the garbage collection)
			# So we know if we find one, it will have 1 child, which is a Card object.
			for obj in $ViewPopup/CardView.get_children():
				cardsArray.append(obj.get_child(0))
	return cardsArray
