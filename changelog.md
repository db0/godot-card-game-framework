# Changelog

## 0.9 (In progress)

* Added viewport focus
* Switched back to control-centric signals. Kept the Area2D base of cards for collision detection only. Ignored z_index except when dragging

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
