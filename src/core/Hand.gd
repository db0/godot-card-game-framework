# A type of [CardContainer] that stores its Card objects with full visibility
# to the player and provides methods for adding new ones and reorganizing them
class_name Hand
extends CardContainer

# Specifies the behaviour to follow when trying to draw a card and we
# exceed our hand size
enum ExcessCardsBehaviour {
	DISALLOW
	ALLOW
	DISCARD_DRAWN
	DISCARD_OLDEST
}

# The maximum amount of cards allowed to draw in this hand
# Offsets the hand position based on the configuration
var bottom_margin: float = card_size.y * CFConst.BOTTOM_MARGIN_MULTIPLIER
# During _read(), this variable will be populated with a node from cfc.NMAP
# according to the name specified in excess_discard_pile_name
var _excess_discard_pile : Pile = null

# Specify the name of the pile to discard excess cards
# When "Discard Drawn" or "Discard Oldest" is specified
# in excess_cards
export var excess_discard_pile_name : String
# The maximum hand size. What happens if this is exceeded is determined
# by `excess_cards`
export var hand_size := 10
# Determines the behaviour of cards over the hand limit
# * DISALLOWED: When hand is at limit, no more cards will be added to it
# * ALLOWED: More cards than the limit can be added to the hand. The developer
#	has to provide some logic on how to deal with the excess
# * "DISCARD_DRAWN": When cards exceed the limit, the new card will be
#	automatically discarded
# * "DISCARD_OLDEST": When cards exceed the limit, the oldest card in the
#	hand will be automatically discarded
export(ExcessCardsBehaviour) var excess_cards

onready var _counter_cards = $Counters/Cards

func _ready() -> void:
	add_to_group("hands")

func prepare_excess_discard_pile() -> void:
	if excess_discard_pile_name\
			and not _excess_discard_pile\
			and cfc.NMAP.has(excess_discard_pile_name.to_lower()):
		_excess_discard_pile = cfc.NMAP[excess_discard_pile_name.to_lower()]


func _process(_delta: float) -> void:
	_counter_cards.text = "Hand: " + str(get_card_count()) \
			+ "/" + str(hand_size)


# Button which shuffles the children [Card] objects
func _on_Shuffle_Button_pressed() -> void:
	shuffle_cards()


# Function to connect to a card discard signal
func _on_DiscardRandom_Button_pressed() -> void:
	var card = get_random_card()
	if card:
		card.move_to(cfc.NMAP.discard)


# A wrapper for the CardContainer's get_last_card()
# which make sense for the cards' index in a hand
func get_rightmost_card() -> Card:
	return(get_last_card())


# A wrapper for the CardContainer's get_first_card()
# which make sense for the cards' index in a hand
func get_leftmost_card() -> Card:
	return(get_first_card())


# Visibly shuffles all cards in hand
func shuffle_cards() -> void:
	# When shuffling the hand, we also want to show the player
	# So execute the parent function, then call each card to reorg itself
	.shuffle_cards()
	for card in get_all_cards():
		card.interruptTweening()
		card.reorganize_self()
	move_child($Control,0)
	emit_signal("shuffle_completed", self)

# Takes the top card from the specified [CardContainer]
# and adds it to this node
# Returns a card object drawn
func draw_card(pile : Pile = cfc.NMAP.deck) -> Card:
	var card: Card = pile.get_top_card()
	# A basic function to pull a card from out deck into our hand.
	if card:
		card.move_to(self)
	return(card)


func get_final_placement_node(card: Card) -> Node:
	var container : Node = self
	if card in get_all_cards():
		return(container)
	prepare_excess_discard_pile()
	match excess_cards:
		ExcessCardsBehaviour.DISALLOW:
			if _get_modified_card_count() < hand_size:
				container = self
			else:
				container = card.get_parent()
		ExcessCardsBehaviour.ALLOW:
			container = self
		ExcessCardsBehaviour.DISCARD_DRAWN:
			if _get_modified_card_count() < hand_size:
				container = self
			elif _excess_discard_pile:
				container = _excess_discard_pile
			else:
				container = card.get_parent()
		ExcessCardsBehaviour.DISCARD_OLDEST:
			container = self
			if _get_modified_card_count() >= hand_size \
					and _excess_discard_pile:
				get_card(0).move_to(_excess_discard_pile)
	return(container)


# Overrides the re_place() function of [CardContainer] in order
# to also resize the hand rect, according to how many other
# CardContainers exist in the same row/column
func re_place() -> void:
	# This variable records how the start position of the hand
	# should be modified, depending on how many other containers
	# are on its left
	var start_pos_left := 0.0
	# This variable records how the total size of the hand
	# should be shrunk, depending on how many other containers
	# are on its row
	var others_rect_x := 0.0
	# same as start_pos_left but for vertically aligned hands
	var start_pos_top := 0.0
	# same as others_rect_x but for vertically aligned hands
	var others_rect_y := 0.0
	# First we put the hand in its expected location, based on nothing
	# else but its anchor
	.re_place()
	# Hook for the debugger
	# I could figure this out from the hand anchor, but this way
	# is easier to understand.
	# We simply go through all the possible hand placements (we assume the
	# hand is always placed in the middle)
	for group in ["top","bottom", "left", "right"]:
		if group in get_groups():
			# We check how many other containers are in the same row/column
			for other in get_tree().get_nodes_in_group(group):
				# For top/bottom placements, we modify the x-axis of the hand
				if group in ["top", "bottom"] and other != self:
					# If the container we're checking is on the left
					# Of the hand, we need to adjust the hand's starting position
					if "left" in other.get_groups() \
							and other.position.x + other.control.rect_size.x > start_pos_left:
						start_pos_left = other.position.x + other.control.rect_size.x
					# For every other container in the same row (top or bottom)
					# we sum their rect_size.x together
					if other.accumulated_shift.y == 0:
						others_rect_x += other.control.rect_size.x
				# for left/right placements, we modify the y-axis of the hand
				# as we assume it's oriented vertically
				if group in ["left", "right"]:
					# If the container we're checking is on top
					# of the hand, we need to adjust the hand's starting position
					if "top" in other.get_groups() \
							and other.position.y + other.control.rect_size.y > start_pos_top:
						start_pos_top += other.position.y + other.control.rect_size.y
					# For every other container in the same column (left or right)
					# we sum their rect_size.y together
					others_rect_y += other.control.rect_size.y
	# If the hand is oriented horizontally, we reduce its size by other
	# containers on the same row
	if "top" in get_groups() or "bottom" in get_groups():
		$Control.rect_size.x = get_viewport().size.x - others_rect_x
		position.x = start_pos_left
		$Control.rect_size.y = card_size.y
	# If the hand is oriented vertically, we reduce its size by other
	# containers on the same column
	if "left" in get_groups() or "right" in get_groups():
		$Control.rect_size.y = get_viewport().size.y - others_rect_y
		position.x = start_pos_top
		$Control.rect_size.x = card_size.x
	if placement == Anchors.CONTROL:
		# This yield allows the other control nodes to set their side
		# In which case the hand, which is typically set to expand vertically
		# doesn't expand too much
		yield(get_tree(), "idle_frame")
		$Control.call_deferred("set_size", get_parent().rect_size)
#		$Control.rect_size = get_parent().rect_size
#		print_debug(get_parent().rect_size)
	# We also need to adjust the hand's collision area to match its new size
	call_deferred("_adjust_collision_area")

	# If the hand is supposed to be shifted slightly outside the viewport
	# we do it now.
	if placement == Anchors.CONTROL:
		# When the hand is adjusted by the parent control, its default position should always be 0
		position.y = bottom_margin
	else:
		# When the hand is adjusted by its anchor
		# we need to move adjust it according to the margin
		position.y += bottom_margin
	# Finally we make sure the cards organize according to the new
	# hand-size.
	call_deferred("_init_control_size")
	if not cfc.ut:
		yield(get_tree(), "idle_frame")
	for c in get_all_cards():
		c.position = c.recalculate_position()

func _adjust_collision_area() -> void:
	$CollisionShape2D.shape.extents = $Control.rect_size / 2
	$CollisionShape2D.position = $Control.rect_size / 2
	highlight.rect_size = $Control.rect_size

# Overridable function for counting cards
func _get_modified_card_count() -> int:
	return(get_card_count())
