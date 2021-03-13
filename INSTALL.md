# Godot Card Game Framework Installation

Simply copy the src folder to your project.

[We've created a quickstart guide](tutorial/QUICKSTART.md) which takes you up to the point where you're creating your first custom card. Once you've done this, continue with the installation guide for more detailed information.

You can rename the folder or any subfolders as you wish to fit your directory structure, just make sure you do it within Godot to allow it to rename all instanced scenes.
However if you do so, you'll also need to adjust the variables starting with `PATH_` inside `CFControl.gd`.

Technically, the tcsn files inside the `res://src/core` are optional but practically it would be very difficult to design them from scratch. Instead we've made them sufficiently modular, that you can easily modify all relevant
parts for your card game by modifying inherited scenes only.

If you insist on modifying scenes inside core, use this approach at your own risk and be aware that if you try to upgrade the framework, it is likely going to replace your modifications and break your game, so you'll be left using the same version.

**It is strongly suggested you do not modify the scenes inside `res://src/core`.** If you have a good reason why you must be able to modify a scene in core, please open a issue to tell us about it, and we'll try to make that part customizable via inherited scenes instead.

On the other hand, te scripts and scenes inside `res://src/custom` are demontstration. They are just there to create a sample setup that we suggest you use when fitting this framework to your needs.

A few notes about the custom scenes.

While everything in there can be modified, some files need to exist in one form or another.
* You **need** a board scene, which you will load into your Main.tcsn "Board Scene" variable. The current provided CGFBoard.tcsn is full of demo functions and you can safely delete everything inside except the class extends declaration.
* You **need** CardConfig.gd, but it is in custom because its contents should change from game to game, and it should not be overriden via an upgrade.
* You **need** CustomScripts.gd, even if it custom_script() function does not match anything.
* You **need** CFConst, but you should customize its constants to fit your needs. It is in custom so that you do not lose your changes during an upgrade.
* You **need** at least 1 Card Back, 1 Card Front and 1 CardManipulationButton scene, to link to your card templates.
* You **need** at least 1 Info Panel Scene. You can re-use CGFInfoPanel.tcsn

All other files, especially those starting with "CGF" can be deleted, or you can keep them around for reference.


## Global configuration

The framework uses a common singleton called CFControl to control overall configuration.

It also uses a core reference class called CFConst which defines the behaviour of the framework


1. Add CFControl.gd as an autoloaded singleton with name 'cfc'

2. Edit the CFConst.gd and adjust any properties according to your game. For example CARD_SIZE will adjust the size of all your cards in the game as well as the CardContainers that host them.

Whenever your game is loaded, all your card containers and your board will be mapped inside cfc.NMAP.
This way if you want to quickly refer to your pile called, say, "SuperCards" all you need to do is refer to `cfc.NMAP.supercards` (in lowercase always)

## Card class

The below instructions will set up your game to use the `Card` class as a framework for card handling.

1. Start by creating an inherited scene based on `CardTemplate.tcsn`. We suggest you create one scene per card type in your game.
	Add those card scenes into either custom/cards directory, or another directory of your preference.
1. If the card type is supposed to be attached to others, check the "Is Attachment"
1. If you have designed your own card back scene, modify the card_back variable to point it to your own card back scene. Make sure your card back extends CardBack.
1. Either use the provided template `res://src/custom/CGFCardFront.tscn` or create your own. Then adjust the card_front variable to point it. To design from scratch, make sure its script extends CardFront.
	Ensure you populate the card_labels dictionary within with the paths to all your text labels.
1. Either use the provided template `res://src/custom/CGFCardManipulationButton.tscn` or create your own. Then adjust the manipulation_button variable on the ManipulationButtons node to point to it.

If you're going to add extra code for your own game in the card scenes, then:
	* If it's relevant to all cards in your game:
		1. Modify your **instanced scene** from `CardTemplate.tcsn` by detaching its `CardTemplate.gd` script and adding a new script that extends Card. Give it a new class_name.

		```
		class_name MyCustomCard
		extends Card
		```

		2. Make sure any extra scripts for different types of cards, extend your new card's class.
	* If it's only relevant to a specific type of card, remove the script attached to that type's scene, and add a new script. Make that script extend from the Card class or from your own new card class_name.

If you want to customize the `CardTemplate.tcsn`, you should start by creating an inherited scene from it. You should try not to modify the CardTemplate.tcsn directly, as that will be overwritten in case of an upgrade.

You will find that most of the scripts linked into the card are pointing to extension of classes, and they reside in `res://src/custom`. You do not need to keep those. Feel free to extend the classes with a fresh script and setup your own configuration. For example, if you design your own CardFront, simply create a new script called like "MyCardTypeFront.gd" extending class CardFront, and attach it to "MyCardTypeFront.tcsn".

If you want a different node setup for the card scene, be aware that the current layout is very tightly wound in the code.
You may need to do extensive modifications to make sure the code can find the modified node names and positions.

You now need to populate your Card Definitions:
1. Edit CardConfig.gd and define the properties of your cards appropriately. Especially make sure the `SCENE_PROPERTY` is set correctly.
2. Populate your sets inside `src/custom/cards/sets`. Use the provided definitions as a baseline.
	Make sure the properties defined match the labels under Front and that the property you defined as the `SCENE_PROPERTY`, has a value that matches the custom scene names you're using for your different type of cards.

## Hand Class

The below instructions will set up your game to use the `Hand` class as a framework for hand handling.

1. Instance in your board scene, a scene based on `Hand.tcsn`.

2. Adjust its Placement variable on the editor according to where you want to it exist. We suggest Bottom Middle initially

2. If you want to customize the code for your own hand functions,
	modify the `Hand.tcsn` by detaching its `Hand.gd` script and adding a new script that extends Hand. Give it a new class_name.

	```
	class_name MyCustomHand
	extends Hand
	```

2. Connect your card-draw signal to the Hand node and make it call the `draw_card()` (see the custom Deck.tcsn node for a sample of such a signal)

Like with Card, the node layout is tightly woven in the code. Amend at your own responsibility.

## Pile Class

The below instructions will set up your game to use the `Pile` class as a framework for pile handling.

1. Instance in your board scene, as many pile scenes as needed, based on `Pile.tcsn`.
2. Adjust its Placement variable on the editor according to where you want to it exist. Typically you want one of the corners such as Bottom Left or Bottom Right
3. If you want multiple piles to share the same corner, adjust the Overlap Shift Direction of the Pile that you want to be pushed from the corner accordingly.
4. If you have more than 2 piles sharing the same corner, adjust the Index Shift Priority of those that will move. Make sure they're all the same (Higher or Lower)
5. For each pile, decide which Shuffle Style you want to use. Default is "auto"
6. For each pile, decide if the cards inside are by default face-up or face-down. Check the "Faceup Cards" accordingly.
7. In case you want the hand to draw cards from this pile. (See the custom `Deck.tcsn` node for a sample of this setup)
	1. connect your `_on_input_event` signal to self and make it emit a "draw card" signal containing `self` as an argument.
	2. Connect the "draw card" signal to the Hand node's `draw_card()` method.

If you want to customize the code for your own pile functions then:

* If it's relevant to all piles in your game
	1. Modify the `Pile.tcsn` by detaching its `Pile.gd` script and adding a new script that extends Pile. Give it a new class_name.

	```
	class_name MyCustomPle
	extends Pile
	```

* If it's only relevant to a specific type of pile (e.g. deck, or discard), remove the script attached to that type's scene, and add a new script.
	Make that script extend from the Pile class or from your own new pile class_name if you've made one.


Like with Card, the node layout is tightly woven in the code. Amend at your own responsibility.


## Board Class

The Board class is keeping track of cards in-play, but also provides some Unit Testing functionality.

The below instructions will set up your game to use the `Board` class as a framework for you main play area (i.e. the play "board").

2. Extend your board script from the Board class

   `extends Board`

1. If you're not using the provided `CGFBoard.tcsn`, then all you need to do is add a Node2D in the root of your scene and make sure the scene root is called "Board"

Of course without instancing a few Hand or Pile objects, there won't be anything you can do.


## Viewport Focus

The framework includes two forms of showing details about a card. One is simply to scale up a the card a bit while in hand, and the other is to pop-up a new viewport with a copy of the card object in it.

By default out of the box, the game has both active.

In order to customize the main scene while allowing the framework to be upgraded in the future, you should simply create a new scene inheriting `Main.tcsn`, then adjust the "Board Scene" variable to point to your own custom Board scene. Ensure you retain "Main" as the scene name. Then add it as your Main scene in your project settings.

The framework will utilize it automatically if it detects a scene called "Main" as the Main scene (as defined in the project configuration).

If you do not want or need the viewport focus, then you can simply ignore it use use your own Board scene as your Main scene.
However you'll need to make sure table cards are legible as they are since there's no other good way to get a closeup of them without viewports.


## Counters

While not strictly needed for Card Games, it's a very typical aspect where a game will need to modify some numberical value outside of cards. For this purpose we have provided the Counters class.
This class is in turn connected to the ScriptingEngine, so by utilizing it properly, you can make your card scripts interact with the counters of your game.

To use this class:

1. Create any Control node, and add it anywhere you need in your scene tree (typically somewhere under Board).
1. Assign its path inside your custom board's script `_ready()`. This will allow the framework to always be able to locate your counters scene.

	```
	func _ready() -> void:
		counters = $Counters
	```

1. Create a new script for your Counters scene by extending `res://core/Counters.gd`.
1. Inside the new script's `_ready()` function, you need to specify which counters you'll need. See documentation in the provided sample `res://src/custom/CGFCounters.gd`
1. Create a new scene for an individual counter. It has to have at least 1 label on the root node, which will hold the value of the counter to display to the player.
	The label names should match the definitions in the script extended from Counters.
1. From the editor on your counters scene, assign your new counter scene to the "Counter Scene" exported variable.

## Upgrading

This framework has been developed with the idea that you might want to upgrade it with the latest version down the road.

To make sure your game can upgrade its framework, make sure to never modify any scenes inside `res://src/core`. If you need to tweak them, you should instead create an inherited scene and store it in a different folder. You can use `res://src/custom` or any other one of your choice. To achieve this, a lot of scenes, like the CardTemplate.tcsn and the Main.tcsn use variables where you point to customized scenes. You should be storing the customized scenes inside your custom folder as well.

To upgrade the framework, simply download the latest version, exit your project, delete `res://src/core` and copy over the core folder from the new version. You should theoretically be able to just overwrite it, but this will create an issue in case any scenes inside were renamed or deleted.

## Unit Testing

Do the following if you want to use/import the provided unit tests.

1. [install Gut](https://github.com/bitwes/Gut/wiki/Install) and do the relevant setup, if you don't have it already.
  **Important:** Due to https://github.com/bitwes/Gut/issues/239 I had to modify the gut tests for assert_almost_eq and assert_almost_ne to work with Vector2. If you install the offical version, you will start seeing a lot of failures.
  You can either use the GUT version included in this repository (in the assets directory), or manually edit the tests to work (will require a lot of lines of extra code), or manually edit yout gut file tests.gd and adapt the asserts likewise.
2. If you followed the standard Gut instructions, you should have already have created the tests folder, copy all the files inside `tests` to your own `res://tests/unit` directory.
3. Edit TestVars.gd and modify the boardScene const to point to the root board (i.e. where the cards are played) of your game.
4. You need to use the Board class on the root of your game or you need to copy the code inside BoardTemplate.tcsn into your own board (at there's necessary Unit Testing code in there)
5. You need to have a Main.tcsn scene.