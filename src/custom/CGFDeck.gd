# Code for a sample deck, you're expected to provide your own ;)
extends Pile

signal draw_card(deck)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not cfc.are_all_nodes_mapped:
		yield(cfc, "all_nodes_mapped")
	# warning-ignore:return_value_discarded
	$Control.connect("gui_input", self, "_on_Deck_input_event")
	# warning-ignore:return_value_discarded
	connect("draw_card", cfc.NMAP.hand, "draw_card")
	#print(get_signal_connection_list("input_event")[0]['target'].name)

func _on_Deck_input_event(event) -> void:
	if event.is_pressed()\
		and not cfc.game_paused\
		and event.get_button_index() == 1:
		emit_signal("draw_card", self)
