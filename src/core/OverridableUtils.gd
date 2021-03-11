# This class is not instanced with each name. 
# Rather it is instanced directly using its path from cfc
# This allows a game to extend it by extending this class
# and then replacing the path in CFConst.PATH_OVERRIDABLE_UTILS 
# with the location of their extended script.
class_name OVUtils
extends Reference


# Populates the info panels under the card, when it is shown in the
# viewport focus or deckbuilder
func populate_info_panels(card: Card, focus_info: DetailPanels) -> void:
	focus_info.hide_all_info()
	var card_illustration = card.get_property("_illustration")
	if card_illustration:
		focus_info.show_illustration("Illustration by: " + card_illustration)
	else:
		focus_info.hide_illustration()
	for tag in card.get_property("Tags"):
		if CardConfig.EXPLANATIONS.has(tag):
			focus_info.add_info(tag, CardConfig.EXPLANATIONS[tag])
	var card_keywords = card.get_property("_keywords")
	if card_keywords:
		for keyword in card_keywords:
			if CardConfig.EXPLANATIONS.has(keyword):
				focus_info.add_info(keyword, CardConfig.EXPLANATIONS[keyword])
