# Changelog

## 1.9 (Ongoing)

### Bugs

* Fixed crash when window x-axis resized to minimum

### New Features

* Can now mark card definitions with a new meta_property: `"_hide_in_deckbuilder": true`. If you do, they will not be shown in the deckbuilder.
* Deckbuilder will now display the total or filtered count of cards shown
* Added new class: GameStats, which can be used to submit stats to your own instance of [CGF-Stats](https://github.com/db0/CGF-Stats)

#### ScriptingEngine

* spawn_card task now expects a card name, instead of a scene path. Spawned cards have to be defined along with the other cards for this purpose. The card name will be used to setup the spawned card.

## 1.8

### Important

A new custom class has been added called SP, extending ScriptProperties.**You must create it in your own custom folder**. You can copy `res://src/custom/SP.gd` from this repository to your own custom folder.

CFConst  has been adjusted. The following enums have been moved to CFInt, as the developers should not have a reason to modify them: `FocusStyle`, `IndexShiftPriority`, `OverlapShiftDirection`.
You can delete these enums from your own CFConst at your leisure. However if you delete them, you need to adjust CFConst.FOCUS_STYLE

New CardConfig property added: `NUMBER_WITH_LABEL`. Any labels specified here, will have their Name as part of their label text. I.e. if you number if 4, and you property is "Cost", the label text will be "Cost: 4".
This was the dedfault behavour until now, but now it allows you to have numbers without a label.
**You will need to specify this property, even if it's an empty list**

Also it's not possible to not use a compensation label. If you specify an empty string as the `compensation_label`, then the game will not try to adjust the size of anything. This assumes you have a card
Layout that doesn't need to be dynamically adjusted for missing text.

`common_pre_move_scripts()` and `common_post_move_scripts()` have changed the variables they expect. if you've extended them, you need to replace the arg `scripted_move: bool` with `tags: Array` and use it accordingly.
tags will contain the tags send to the `move_to()` method

* Fixed uppercased-set Card Front labels messing with their text autoadjustment y-size

### Tweaks

* Whitespace separation of column in deckbuilder won't variate with number of buttons anymore.

### New Features

* Made label size compensation optional.
* Number properties can now be displayed without a label (i.e. just the number)
* 1/10 deck names with adjectives will now also contain an adverb.
* Can now set a string integer with an operator ("-1", "+5" etc) as a numerical property, to specify a modification to the existing number

#### ScriptingEngine

* Can now filter individual script tasks based on the trigger card.
* per can now calculate based on the properties/tokens on previous subjects using `"subject": "previous"`. However for this to work, the parent task also has to have `"subject": "previous"` set.
* Can now set "is_else" : true tasks, which will only be executed if the "is_cost" tasks cannot be paid
* Refactored the way the script task loop is handled. If you've extended the ScriptingEngine, you will need to adjust your _init()
* class SP now moved to custom and is a dummy class extending ScriptProperties (which contains the old SP). This way developers can extend the SP class while still allowing drag&drop upgrades
* Can now store an integer with the difference of mod_tokens or mod_counter operations. This allows to do effects such as "Discard all blue credits. Draw a card per credit discarded".
* Can now compare card properties against counter values
* temp_mod_counters and temp_mod_properties can now use retrieve_integer on their values
* All card manipulation Signals now send a list of tags marking the type of effect that triggered them. By Default it's "Manual" for 


## 1.7 

### Important

CFConst  has been adjusted. If you are working on your own copy of CFConst, you will need to adjust  the following constants

* New constant added: PATH_MOUSE_POINTER. This allows the game to add extra functionality to the mouse pointer script. This constant needs to exist but can be redirected to a custom scene.
* New constant added: SETTINGS_FILENAME. This determines the path in which to store game settings on the disk.
* New constant added: DECKS_PATH. This determines the path in which to store the player-made deck on the disk.
* New constant added: PATH_DECKBUILDER. This points to the DECKBUILDER scene to use in the game. This allows each game to customize the deckbuilder further using instanced scenes.

## New Features

* Added a Deck builder, which allows the players to create, save and load decks for each game. The Deck builder supports filters and is very customizable.
* If the top card of a Pile is Faceup or Facedown and viewed, it will now be seen in the viewport focus when mouse hovers over the pile.
* Added framework which enables to store game settings to disk
* Game can now be paused which prevents all interaction from the player

#### ScriptingEngine

* Added new `view_card` task which allows scripts to mark a card as viewed while face-down

## 1.6

### Important
CFConst  has been adjusted. If you are working on your own copy of CFConst, you will need to adjust  the following constants

* SCRRIPT_SET_NAME_PREPEND renamed to **SCRIPT_SET_NAME_PREPEND**
* PATH_PER_ENGINE renamed to **PATH_SCRIPT_PER**

Some ScriptProperty consts have been adjusted to allow `counter_modified` signal to work using the same trigger filter code.

* FILTER_TOKEN_COUNT > FILTER_COUNT
* TRIGGER_V_TOKENS_INCREASED > TRIGGER_V_COUNT_INCREASED
* TRIGGER_V_TOKENS_DECREASED > TRIGGER_V_COUNT_DECREASED
* TRIGGER_NEW_TOKEN_VALUE > TRIGGER_NEW_COUNT
* TRIGGER_PREV_TOKEN_VALUE > TRIGGER_PREV_COUNT

### New Features

* Added new overridable common_pre_move_scripts() method to Card to allow developers to modify the end location of a card.

#### ScriptingEngine

* The scripts property of a card, can be populated with some triggers, without affecting the other triggers defined in Script Definitions
	This allows, for example, for some cardscripts to be added during runtime with a custom trigger, then executed immediately.
* Added new task: `execute_script` which allows one to execute scripts on other cards. This can be useful when, for example, you want a card that activates other cards with modifiers.
* Two new keys added which temporary modify counters or subject card propeties during execution of a task. 
* Added new exported var for a Card: `initiate_targeting_scripts_from_hand_drag`. It allows to initiate scripts which require targeting, by long-clicking the card while in hand. Great for use with Action cards.
* Card's move_to will now be aware when it's moving cards due to scripts. This can give more flexibility to developers
* Alterants can now affect the retrieved number of counters, tokens or numeric card properties. This allows effects such as "Increase the power of all soldiers by 1"
* Added counter_modified signal.
* Added new trigger filters where a card can decide to activate or not, based on the amount of cards on board/cardcontainer. I.e. have an effect such as "if there's at least 3 creatures in discard pile".
* Added a caching feature for alterants. The cache is flushed after every game-state change.
* Tasks which use `"subject": "previous"` can now be put before a task which finds the target, as long as they're not `is_cost` and the targeting task `is_cost`.

### Tweaks

* Card.common_move_scripts() has been renamed to Card.common_post_move_scripts()
* DISABLE_DROPPING_TO_CARDCONTAINERS, DISABLE_DRAGGING_FROM_HAND, DISABLE_DRAGGING_FROM_BOARD, and DISABLE_DRAGGING_FROM_PILE have been moved as exported variables to the CardTemplate now
	Each card type can have its own settings that fit how it works.
* Renamed SignalPropagato's `_on_Card_signal_received()` to `_on_signal_received()`
* Improved performance when a lot of cards are in the game.
* Size of pile will now stay reasonable, even with massive amount of cards.

### Bugfixes

* TargetingArrow will now signal targeting_completed when it didn't find a target as well
* execute_scripts will now properly check for is_cost for itself and its target
* When muliple card fields are empty, the compensation text will not properly increase its font to utilize the extra space

#### ScriptingEngine

* ScriptingEngine won't crash on an empty target on the second invocation of the same script.
* execute_scripts will wait until all ScriptingEngine task have been completed before proceeding.


## 1.5

### Important

CFConst  has been adjusted. If you are working on your own copy of CFConst, you will need to adjust  the following constants

* CANNOT_PAY_COST_COLOUR has been removed
* CostsState has been added as a dictionary of Colors (name is CameCase to simulate enum usage). The entry "OK" is mandatory to exist.

Hand class has been adjusted to export some more vars. Check them out and make sure you haven't lost any other exported var settings.

### New Features

* Added common_pre_execution_scripts() which is executed before each script call. It is meant to be overriden for use in for common scripts per card type, instead of adding the same task on each card.
* Added common_post_execution_scripts() which is executed after each script call. Similar purpose to common_pre_execution_scripts()
* Can now specify the hand size for each Hand class on the editor
* Now can specify on each hand, if cards over the maximum are allowed to be drawn and what happens then
	In case DISCARD_DRAWN or DISCARD_OLDEST is specified, then an excess_discard_pile_name has to be also specified. The game then will seek a pile with this name and put the excess cards in there as specified.
	ScriptingEngine will also respect this setting.
* Added a counter framework. Developers can add a counters node to their board and store it in a counters variable. Inside they can define as many counters as they need, and they can also change the layout of the scene


#### ScriptingEngine

* New task added "mod_counters" to make use of the new counters framework.
* counters will also be taken into account via the PerEngine using "per_counter".
* counters can be set as script costs.
* Alterants added to ScriptingEngine. These are scripts which are always active on the card, and modify other scripts before they take effect
	They are added under a new key: ["Alterants"](https://github.com/db0/godot-card-game-framework/wiki/SP#key_alterants) and each has its own filter specifying which kind of scripts it can modify.


### Tweaks

* GridPlacementSlots won't highlight anymore when the card doesn't belong in them (i.e. the card cannot be placed on the board, it can only be placed in a differently named grid)
* The demo now has a custom instance of Hand.tcsn and the DiscardRandom is a set as a custom button in it.

### Bugfixes

* When filtering triggers for the number 0, it should not always match
* Framework won't crash when trying to reduce a token that has not been added yet.

## 1.4

### Important

CFConst  has been adjusted. If you are working on your own copy of CFConst, you will need to adjust  or add the following constants

* PATH_PER_ENGINE (New Addition)
* ATTACHMENT_OFFSET (Modified to be an array)

### New Features

* Added ability for BoardPlacementGrid to be set to autoextend based on exported var. Only really useful for scripting, when a script requests a position to said grid, it will automatically add a new slot.
	(defaults to false)
* Attachments can now be offset in any direction. Customized on the scene itself.  Collaboration with [@zombieCraig](https://github.com/zombieCraig).
	* **Note**: You will need to adjust CFConst.ATTACHMENT_OFFSET in case you're working on your own copy of CFConst.
* Can set a card type for Grid Autoplacement. The card will always attempt to position itself inside the specified grid. If it cannot, it will remain where it was. If the grid can auto-extend, it will do so to host the card.
* Specified compensation label will increase when other labels are hidden because they are empty
* Now can specify specific number properties which will cause the label to hide when they're set to 0
* Added common_move_scripts() method in CardTemplate which is called after a card moves. This can be overriden by developers to call scripts for whole groups of cards.
* Added a way to generate a random seed each game.. Demonstration board displays the random seed.

#### ScriptingEngine

* Added support for placing cards directly into Grids.
* Having enough space in a grid can also be considered a cost check.
* Now can spawn more than 1 card at the same time.
* Spawned cards can be placed in grids directly.
* Now supports AND, OR conditionals in filters.
* Now supports ne/gt/lt/ge/le comparisons on numbers.
* Now supports "not equal" comparison on strings.
* Now supports runtime calculation of power of effects using the "per_" key.

### Tweaks
#### ScriptingEngine

* Consolidated move_card_cont_to_cont to move_card_to_container
* Consolidated move_card_cont_to_board to move_card_to_board

You have to adjust any scripts which used the former two tasks, to use the latter two. No need to adjust any keys.


## 1.3

### New Features

* Refactoring was done so that the Framework is easier to upgrade to a newer version by simply overwritting the `res://src/core` folder with the newer version
  * Moved CFConst to `res://src/custom` which is not meant to be overwritten. This will ensure tweaks to the way the engine works will remain after an upgrade.
  * Main.tcsn now doesn't have the board scene instanced directly. Rather you specify the board scene via an exported variable.
	This allows developers to create a new inherited Main.tcsn scene and set it to load their own custom board scene. This in turn allows a developer to upgrade their Main.tcsn in `res://src/core` and take advantage of any upgrades, while not losing their own customizations
  * Moved Card Front to its own instance, with a same method used for card back. Now inherited card scenes from CardTemplate can have radically different Front layout from each other.
  * Moved Manipulation buttons to code, instanced from a single button scene. Code exists inside ManipulationButtons class and can be overriden by any card that uses its own script to extend it.
  * Developers can now also specify the Scripting Engine location inside CFConst. This will allow them to extend its functionality with more tasks, specific to their game.
* Can now define global CARD_SIZE to CFConst. Now you can change card size globally and all cardcontainers will also adjust their size accordingly.
* Developers do not need to define critical node locations in CFConst anymore.
* Made it easier for other devs to extend the ScriptingEngine
* Added configuration option that selectively disables drag or drop.
* Added overridable function `check_play_costs()` which can determine on runtime is costs can be paid, and allow the card to be dragged from hand
* Can now create grid containers which will highlight when a card is being dragged on top of them so signify the position the card will move to.
* Can now specify where each card type will be able to drop on the board. Options are Anywhere, Any Grid only, Specific Grid only, or None (which means this card type cannot be dropped on the board at all)

## 1.2

### New Features

* Pile name and card count will be displayed. Possibility to add an image or colour to the pile which will not be shown when there's cards inside.
* Added new card back that meets proper gambling symmetry rules.  - Contribution by [@zombieCraig](https://github.com/zombieCraig).
* A pile can now be renamed from the editor properties, instead of having to edit node properties and look for the label. - Contribution by [@zombieCraig](https://github.com/zombieCraig).

### Tweaks

* Card Back scene has to be defined in the new card_back_design exported variable. You have to select the scene you want from for each different card type (assuming they're using a different one)
* Switched BoardTemplate to expect Control instead of Node2D, to allow potential GUI elements to orient themselves easier.
* Card back now can include the "Viewed" node in in any form they wish.
	The function set_is_viewed() will handle setting the viewed node to visible or not.
	if another method to show viewed has been setup for this card back, then the set_is_viewed() function can be overriden.


### Bugfixes

* Card properties will now properly ignore properties defined with _underscore in the name start.
	If the property's label is missing and the property does not start with an underscore, the framework will print out an error. - Contribution by [@zombieCraig](https://github.com/zombieCraig).

## 1.1

We're now [added a quickstart guide](tutorial/QUICKSTART.md)!

### New Features

* Card Front labels should be defined in the _card_labels variable. This is defined inside `_init_front_labels()`. This allows any developer to modify the Front control nodes layout and still allow the setup() to find the label nodes to modify them.

### Tweaks

* Synchronized card focus animations
* Changed colour for the Requirements label to make it more obvious in the demonstration that an empty label is hidden
* If a label expands too much in rect._size.y, a pre-specified label will shrink to compensate. Defined in CardConfig.

## 1.0

First stable release is here! We will attempt to not break (too much) existing names and calls from this point on.

### New Features

* Pile shuffle is now animated - Contribution by [@vmjcv](https://github.com/vmjcv).
* Many types of pile shuffle animation and ability to select a different one per pile.
	Available anims:
   * corgi
   * splash
   * snap - Contribution by [@vmjcv](https://github.com/vmjcv).
   * overhand - Contribution by [@EasternMouse](https://github.com/EasternMouse).
* Piles and Hand will highlight when a dragged card hovers over them to display where the card will be dropped when released.
* Framework godot source directories can now be renamed or moved.
* Added "Placement" option to select where each CardContainer will be setup on the board
* If CardContainers have a specified placement on the board, a table resize will automatically move them to the right location. This means that stretch mode "disabled" is usable now.
* Added switch to disable placement on board (for games that don't use it)

#### Scripting Engine

* Added new task "modify_properties", which allows scripts to change the card details.
* Added new task "ask_integer", which allows the script to request a number from the player. Subsequent tasks can pull that number for their own effects
* Some tasks can now use the new "subject_count" modulator which allows to affect more than 1 card.
* Moving cards from containers can now be treated as a cost.

### Bugfixes

* Refactored how mouse detection works. Should avoid clicking or highlighting the wrong card
* Now clicking on buttons or tokens too long should not try to drag the card. Likewise clicking them too fast shouldn't try to execute scripts

## 0.12

### New Features

* Scipting Engine target finding now supports tutoring cards from deck
* Scipting Engine target finding now supports affecting multiple cards from the board by filtering their properties
* Scripting Engine now supports cards with multiple choices for abilities.
* Scripting Engine now supports cards with optional abilities
* Hand shape can now be oval (default) - Contribution by [@vmjcv](https://github.com/vmjcv).
* Font-size will decrease when it amount of chars is too large, in order to stay within the defined label rectangle - Contribution by [@vmjcv](https://github.com/vmjcv).

### Bugfixes

* Fixed manipulation buttonsd messing with player's actions


## 0.11

* Added new card back
* Made the card back glow-pulse
* Can add or remove tokens from cards
* Piles now display the size of the card stack
* Cards in Piles are now places face-up or facedown depending on the pile config
* Card definitions can now be created using json
* Supports multiple sets of card and script definitions
* Added [Scripting Engine](https://github.com/db0/godot-card-gaming/wiki/ScriptDefinitions)!
  * Tasks supported:
    * Rotate Card
    * Flip card face-up/down
    * Move card to a CardContainer
    * Move card to board
    * Move card from Container to Container
    * Spawn new card
	* Shuffle CardContainer
	* Attach to card
	* Attach card to self
  * Trigger-based execution supported:
    * Card rotated
	* Card flipped
	* Card viewed
	* Card moved to board
	* Card moved to hand
	* Card moved to pile
	* Card_tokens_modified
	* Card attached to another
	* Card unattached from another
  * Filtering of triggers supported:
	* Card properties
	* Card rotation degrees
	* Card facing
	* Source container of move
	* Destination container of move
	* Token count
	* Token increase/decrease
	* Token name
* Scripting also support setting some tasks as costs required and targetting cards on the table.


In case you're wondering why the FocusHighlight node has two children panel nodes, instead of making it itself a Panel node.

This is because of https://github.com/godotengine/godot/issues/32030 which doesn't not consistently apply glow effects to vertical lines.

As such, I had to create the vertical and horizontal lines sepearately and apply different intensity of colour to each, to make the glow effect match.

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
