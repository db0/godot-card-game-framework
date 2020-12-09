
# Godot Card Game Framework 0.12

![Codot Card Game Framework preview image](preview.png "Codot Card Game Framework preview image")

This framework is meant to provide well-designed, statically-typed, and well-commented classes which you can plug into any potential card game to provide a polished way to handle typical behaviour expected from cards in a game.

**Important: This is still a pre-release and is subject to heavy changes as I figure things out.**

You can still use it as is, but be aware that newer release might substantially rework how things work, thus requiring a new integration if you want to use them.

Once we hit v1.0 things should become more stable.

Pull requests are more than welcome ;)

## Usage

Most of the card manipulation functionalities work without any extra work, as long as the relevant scenes have been setup correctly (see #Installation section). For example, the code which handles moving cards around or focusing on them etc should work out of the box.

However some effects require some trigger, such as targeting of cards etc. The method calls to perform these are available to use and some demo functions have been provided to understand how it works, but it is expected that each game will provide their own logic in their own scripts to call the relevant methods.

You can find documentation about all the provided methods [in the wiki](https://github.com/db0/godot-card-gaming/wiki)

### Demonstrations

#### Targeting

Right-click and hold on a a card to begin dragging a targeting arrow. Release right-click on top of a card to target it. A print will inform you of the target name and container

#### Attachments

Click on the "Enable Attachment" toggle to make all cards act as attachments and therefore allow them  to attach to others.

### Card Rotation

Click on either the 'T' or '@' buttons. Click again the same button to revert to  0 degrees.

### Tokens/Counters

Click on the 'O' Button, to start adding random tokens to the card.

Click on the +/- buttons next to each Token to add/remove that specifically

### Card Flip Face-Up/Face-Down

Click on the 'F' button to exchange between these two states

### Card Scripts

The first four cards you will draw from your deck each have different prepared automation. You can double click any of them in the hand or board to see their effects.

Some of them have also effects that trigger off of other effects.

Mind that their script effect change, depending on whether they're in the hand or board

## Installation

Copy the src folder to your project

Strictly speaking, the tcsn files inside are optional but **highly recommended** as they come preset with all the node configuration needed to run all interactions defined in the code properly.

While you could simply use only the provided scripts, you will then need to adapt your own scenes to contain the nodes required with retaining the the correct name.

A notable exception is the optional Board.tcsn. While referenced from the Main.tcsn, this one is the easiest to replace with your own custom board.
Just remember to adjust Main.tcsn to have your own Board scene under ViewportContainer/Viewport)

**It is strongly suggested you start by importing the provided scenes in src and modify them further to fit your own requirements.**

For example, you can easily switch the CardTemplate.tcsn's "Front" node to a TextureRect and it will not affect the framework.

However remove the ViewPopup Control node from the CardContainer scene, things will start crashing.

The scripts and scenes inside /src/custom are optional. They are just there to create a sample setup of the capabilties of the framework.

### Global configuration

The framework uses a common singleton called cfc to control overall configuration.

1. Add cfc.gd as an autoloaded singleton with name 'cfc'

2. Edit the `var nodes_map` in cfc.gd in the "Behaviour Constants" section, to point to your board and other container scenes (Deck, discard etc)

4. Edit the pile_names and hand_names arrays with the names of your respective piles (deck, discard etc) and hand(s).


### Card class

The below instructions will set up your game to use the `Card` class as a framework for card handling.

1. Instance a scene based on `CardTemplate.tcsn`. We suggest you create one scene per card type in your game.
	Add those card scenes into the custom/cards folder where you'll keep your game assets.
2. If the card type is supposed to be attached to others, check the "Is Attachment"

2. If you're going to add extra code for your own game in the card scenes, then:
	* If it's relevant to all cards in your game:
		1. Modify the CardTemplate.gd by removing its `CardTemplate.gd` as script and adding a new script instead, that extends Card. Give it a new class_name.
		
		   `extends Card`
		   
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

### Hand Class

The below instructions will set up your game to use the `Hand` class as a framework for hand handling.

1. Instance a scene based on `Hand.tcsn`. Adjust its position on your board with code or visually

2. If you want to customize the code for your own hand functions,
	modify the Hand.gd by removing its `Hand.gd` as script and adding a new script instead, that extends Hand. Give it a new class_name.

   `extends Hand`

2. Connect your card-draw signal to the Hand node and make it call the `draw_card()` (see the custom Deck.tcsn node for a sample of such a signal)

If you want to customize the `Hand.tcsn`, the following nodes are fairly safe to manipulate

* The `$Control` rect_size property
* Everything under `$Control/ManipulationButtons` except `$Control/ManipulationButtons/Tween`

Like with Card, the node layout is tightly woven in the code. Amend at your own responsibility.

### Pile Class

The below instructions will set up your game to use the `Pile` class as a framework for pile handling.

1. Instance as many scenes as needed, based on `Pile.tcsn`. Adjust their position on your board with code or visually

2. For each pile, decide which shuffle style you want to use. Default it "auto"
3. For each pile, decide if the cards inside are by default face-up or face-down. Check the "Faceup Cards" accordingly.

4. If you want to customize the code for your own pile functions then:
	* If it's relevant to all piles in your game
		1. Modify the Pile.gd by removing its `Pile.gd` as script and adding a new script instead, that extends Pile. Give it a new class_name.
		
		`extends Pile`
		
	* If it's only relevant to a specific type of pile (e.g. deck, or discard), remove the script attached to that type's scene, and add a new script.
		Make that script extend from the Pile class or from your own new pile class_name if you've made one.

2. Connect your card-draw signal to the Hand node and make it call the `draw_card()` (see the custom Deck.tcsn node for a sample of such a signal)

If you want to customize the `Pile.tcsn`, the following nodes are fairly safe to manipulate

* The `$Control` rect_size property
* Everything under `$Control/ManipulationButtons` except `$Control/ManipulationButtons/Tween`
* `$CenterContainer`

Like with Card, the node layout is tightly woven in the code. Amend at your own responsibility.


### Board Class

The Board class is keeping track of cards in-play, but also provides some Unit Testing functionality.

The below instructions will set up your game to use the `Board` class as a framework for you main play area (i.e. the play "board").

2. Extend your board script from the Board class

   `extends Board`

1. If you're not using the provided Board.tcsn, then all you need to do is add a Node2D in the root of your game.

Of course without instancing a few Hand or Pile objects, there won't be anything you can do.

### Viewport Focus

The framework includes two forms of showing details about a card. One is simply to scale up a the card a bit while in hand, and the other is to pop-up a new viewport with a copy of the card object in it.

By default the game has both active, but the viewport focus requires a bit more extensive setup to be usable by your game. Specifically you need to setup a parent scene which utilizes multiple viewports.

If you do not already have anything like this, you can simply use the Main.tcsn scene as a template and modify accordingly. The framework will utilize it automatically if it detects a Main.tcsn as the root.

If you want to use your own root scene, then you can simply extend it from the ViewportCardFocus class to inherit all the required methods

If you do not want or need the viewport focus, then simply ignore it. However you'll need to make sure table cards are legible as they are since there's no other good way to get a closeup of them without viewports

### Unit Testing

Do the following if you want to use/import the provided unit tests

1. [install Gut](https://github.com/bitwes/Gut/wiki/Install) and do the relevant setup, if you don't have it already.
  **Important:** Due to https://github.com/bitwes/Gut/issues/239 I had to modify the gut tests for assert_almost_eq and assert_almost_ne to work with Vector2. If you install the offical version, you will start seeing a lot of failures.
  You can either use the GUT version included in this repository, or manually edit the tests to work (will require a lot of lines of extra code), or manually edit yout gut file tests.gd and adapt the asserts likewise.
2. If you followed the standard Gut instructions, you should have already have created the tests folder, copy the test_*.gd from /tests/unit inside your own `res://tests/unit`.
3. Edit TestVars.gd and modify the boardScene const to point to the root board (i.e. where the cards are played) of your game.
4. You need to use the Board class on the root of your game or you need to copy the code inside BoardTemplate.tcsn into your own board (at there's necessary Unit Testing code in there)

## Easy Customation

The classes provide some easy customization options, such as how the card move, where they appear etc
Check the "Behaviour Constants" header at the start of the cfc singleton.
For more fine customization, you'll need to modify manually

## Scripting Engine

One of the most powerful features of this framework, is the possibility to easily script each individual card's abilities from start to finish, so that a player only needs to double-click on a card and your code will handle the proper execution. This allows games to very easily create complete rules enforcement of all card abilities, from the simplest to the most tricky ones.

Please see the [ScriptDefinitions](https://github.com/db0/godot-card-gaming/wiki/ScriptDefinitions) documentation for more details

The game comes with some sample scripted cards which can be found under `res://src/custom/cards/sets`.


## Provided features

* **Complete card text and rules enforcement** via provided Scripting Engine! (see scripting features below)
* Tween & GDScript-based animations that look good for card movements.
* Customizable card highlights
* Choice between Oval or Straight hand shape
* Automatic focus-in on cards when moused over in-hand.
* Automatic re-arranging of hand as cards are added or removed.
* Drag & Drop of cards on table and between containers
* Possibility for multiple hands and piles
* Piles of cards represent their size visually.
* Larger image of card when moving mouse cursor over it
* Pop-up buttons for predefined functions on cards and card containers
* Option to look inside the piles and choose cards to move out
* Cards can rotate on the table
* Cards can attach to other cards and move together as a group.
* Cards can target other cards with a draggable arrow
* Can flip cards face-down and view them while in that state
* Can add tokens on cards. Tokens expand in the own drawer for more info.
* Ability to define cards in standard json
* Ability to split card definitions into sets
* Automatically resizing text inside cards to fit the card size.

### Scripting Engine Features

* Can define card scripts in plain text, using simple json
* Can set cards to trigger off of any booard manipulation
* Can filter the triggers based on card properties, or a special subset
* Can define optional abilities
* Can define multiple-choice abilities
* Very easily extensible to your own game's special requirements

## Contributing

Please see the [Contribution Guide](contributing.md)

You can also join us on Discord with this invite code: https://discord.gg/AjZMFY7jD4

## Credits

Some initial ideas were taken from this excellent [Godot Card Game Tutorial video series](https://www.youtube.com/watch?v=WjT5sLMD7Kw). This framework uses some of the concepts but also attempts to create better quality code in the process.