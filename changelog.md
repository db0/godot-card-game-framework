# Changelog

## 0.11 (Ongoing)

* Added new card back
* Made the card back glow-pulse 
* Can add or remove tokens from cards
* Piles now display the size of the card stack
* Cards in Piles are now places face-up or facedown depending on the pile config
* Added Scripting Engine!


## 0.10

* Added visible highlight when mousing over a card
* Can move cards to top/bottom or any index in Card Containers
* Can retrieve cards from top/bottom of Card Containers
* Can retrieve random cards from Card Containers
* Can shuffle Card Containers
* Can attach cards to other cards
* Can target cards with a targetting arrow
* Made highlights glowing
* Enabled ability to make cards face-down
* New button to view face-down cards that appears only when card is faced-down

In case you're wondering why the FocusHighlight node has two children panel nodes, instead of making it itself a Panel node.

This is because of https://github.com/godotengine/godot/issues/32030 which doesn't not consistently apply glow effects to vertical lines.

As such, I had to create the vertical and horizontal lines sepearately and apply different intensity of colour to each, to make the glow effect match.


## 0.9

* Added viewport-based focus
* Switched back to control-centric signals. Kept the Area2D base of cards for collision detection only. Ignored z_index except when dragging
* Added a way to display buttons when hovering over CardContainers and Cards.The buttons would trigger predefined actions.
* Added capability to look inside containers and manipulate cards
* Added a container button which creates a rudimentary popup for seeing the cards inside containers
* Added a container button which shuffles the contained cards
* Added method to get random cards from CardContainer. Added Hand button to trigger it as a demo
* Added capability to rotate cards on table
* Added a card buttons which rotate cards 90 or 180 degrees


## 0.8

* Added capability for any number of hands and/or piles
* Can drop cards into piles
* Can pick up cards from table
* Hand is a type of container (like piles) and behaves similarly to keep things consistent.
* Cards dragged will always be in front of other elements now
* When 2+ cards overlap on the board, game will always pick the top one when clicking to drag.


## 0.7

* Added GUT and initial tests
* Added button to reshuffle cards to the deck
* Added fancy movement
* Made hand into a control container
* Removed config from Card object into an singleton

## 0.6

* Can drag cards
* Can drop cards back to the hand or table

## 0.5

* First published version
* Code for drawing cards to hand
* Automatic reorganization of cards as hand size changes
* Automatic zoom in/out on mouse enter/exit respectively.
