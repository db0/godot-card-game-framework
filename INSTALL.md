# Godot Card Game Framework Installation

Simply copy the src folder to your project.

[We've created a quickstart guide](tutorial/QUICKSTART.md) which takes you up to the point where you're creating your first custom card. Once you've done this, continue with the installation guide for more detailed information.

You can rename the folder or any subfolders as you wish to fit your directory structure, just make sure you do it within Godot to allow it to rename all instanced scenes.
However if you do so, you'll also need to adjust the variables starting with `PATH_` inside `CFControl.gd`.

Strictly speaking, the tcsn files inside are optional but **highly recommended** as they come preset with all the node configuration needed to run all interactions defined in the code properly.

While you could simply use only the provided scrips and classes, you will then need to adapt your own scenes to contain the nodes required with retaining the the correct names.
This is easier said than done so use this approach at your own risk.

**It is strongly suggested you start by importing the provided scenes in src and modify them further to fit your own requirements.**

The scripts and scenes inside /src/custom are optional. They are just there to create a sample setup of the capabilties of the framework.

A notable exception to this is the Board.tcsn.
While optional, it is also referenced from the Main.tcsn and is mandatory to have a board to let the framework work.
Nevertheless, this one is the easiest to replace with your own custom board.
Just remember to adjust Main.tcsn to instance your own Board scene under ViewportContainer/Viewport)

## Global configuration

The framework uses a common singleton called CFControl to control overall configuration.
It also uses a core reference class called CFConst which defines the behaviour of the framework

1. Add CFControl.gd as an autoloaded singleton with name 'cfc'

2. Edit the `var nodes_map` in CFConst.gd in the "Behaviour Constants" section, to point to your board and other container scenes (Deck, discard etc)

## Card class

The below instructions will set up your game to use the `Card` class as a framework for card handling.

1. Instance a scene based on `CardTemplate.tcsn`. We suggest you create one scene per card type in your game.
	Add those card scenes into the custom/cards folder where you'll keep your game assets.
2. If the card type is supposed to be attached to others, check the "Is Attachment"

2. If you're going to add extra code for your own game in the card scenes, then:
	* If it's relevant to all cards in your game:
		1. Modify the `CardTemplate.tcsn` by detaching its `CardTemplate.gd` script and adding a new script that extends Card. Give it a new class_name.

		```
		class_name MyCustomCard
		extends Card
		```

		2. Make sure any extra scripts for different types of cards, extend your new card's class.
	* If it's only relevant to a specific type of card, remove the script attached to that type's scene, and add a new script. Make that script extend from the Card class or from your own new card class_name.

If you want to customize the `CardTemplate.tcsn`, the following nodes are fairly safe to manipulate:

* The `$Control` rect_size property
* The `$Control/Front` node type, as long as it remains a Control type node.
* All children nodes of `$Control/Front`. The labels there are used to populate your card. You'll need to adjust setup() and the Card Definitions if you change their names and positions.
* Everything under `$Control/Back/VBoxContainer` except `$Control/Back/VBoxContainer/CenterContainer` as that is needed to show the viewed status.
* Everything under `$Control/ManipulationButtons`
* `$Debug`

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

If you want to customize the `Hand.tcsn`, the following nodes are fairly safe to manipulate

* The `$Control` rect_size property
* Everything under `$Control/ManipulationButtons` except `$Control/ManipulationButtons/Tween`

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


If you want to customize the `Pile.tcsn`, the following nodes are fairly safe to manipulate

* The `$Control` rect_size property
* Everything under `$Control/ManipulationButtons` except `$Control/ManipulationButtons/Tween`
* `$CenterContainer`

Like with Card, the node layout is tightly woven in the code. Amend at your own responsibility.


## Board Class

The Board class is keeping track of cards in-play, but also provides some Unit Testing functionality.

The below instructions will set up your game to use the `Board` class as a framework for you main play area (i.e. the play "board").

2. Extend your board script from the Board class

   `extends Board`

1. If you're not using the provided `Board.tcsn`, then all you need to do is add a Node2D in the root of your scene.

Of course without instancing a few Hand or Pile objects, there won't be anything you can do.

## Viewport Focus

The framework includes two forms of showing details about a card. One is simply to scale up a the card a bit while in hand, and the other is to pop-up a new viewport with a copy of the card object in it.

By default the game has both active, but the viewport focus requires a bit more extensive setup to be usable by your game. Specifically you need to setup a parent scene which utilizes multiple viewports.

If you do not already have anything like this, you can simply use the `Main.tcsn` scene as a template and modify accordingly. The framework will utilize it automatically if it detects a Main.tcsn as the root.

If you want to use your own root scene, then you can simply extend it from the ViewportCardFocus class to inherit all the required methods.
The Main.tcsn has a fairly simple layout, however it's still not recommended to replace it, but instead to tweak it what has already been provided.

If you do not want or need the viewport focus, then you can simply ignore it.
However you'll need to make sure table cards are legible as they are since there's no other good way to get a closeup of them without viewports

## Unit Testing

Do the following if you want to use/import the provided unit tests.

1. [install Gut](https://github.com/bitwes/Gut/wiki/Install) and do the relevant setup, if you don't have it already.
  **Important:** Due to https://github.com/bitwes/Gut/issues/239 I had to modify the gut tests for assert_almost_eq and assert_almost_ne to work with Vector2. If you install the offical version, you will start seeing a lot of failures.
  You can either use the GUT version included in this repository (in the assets directory), or manually edit the tests to work (will require a lot of lines of extra code), or manually edit yout gut file tests.gd and adapt the asserts likewise.
2. If you followed the standard Gut instructions, you should have already have created the tests folder, copy all the files inside `tests` to your own `res://tests/unit` directory.
3. Edit TestVars.gd and modify the boardScene const to point to the root board (i.e. where the cards are played) of your game.
4. You need to use the Board class on the root of your game or you need to copy the code inside BoardTemplate.tcsn into your own board (at there's necessary Unit Testing code in there)
5. You need to have a Main.tcsn scene.