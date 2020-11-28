# Godot Card Gaming Framework 0.10

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

The first three cards you will draw from your deck each have different prepared automation. You can double click any of them in the hand or board to see their effects. 

Mind that their script effect change, depending on whether they're in the hand or board

## Installation

Copy the src folder to your project

Strictly speaking, the tcsn files inside are optional but **highly recommended** as they come preset with all the node configuration needed to run all interactions defined in the code properly.

While you could simply use only the provided scripts, you will then need to adapt your own scenes to contain the nodes required with retaining the the correct name.

A notable exception is the optional Board.tcsn. While referenced from the Main.tcsn, this one is the easiest to replace with your own custom board.
Just remember to adjust Main.tcsn to have your own Board scene under ViewportContainer/Viewport)

**It is strongly suggested you start by importing the provided scenes in src and modify them further to fit your own requirements.**

For example, you can easily switch the CardTemplate.tcsn's Panel (called "Control") to a TextureRect and it will not affect the framework.

However if you forget to add a ViewPopup Control node into your custom CardContainer scene, things will start crashing.

The scripts and scenes inside /srv/custom are optional. They are just there to create a sample setup of the capabilties of the framework.

### Global configuration

The framework uses a common singleton called cfc to control overall configuration.

1. Add cfc.gd as an autoloaded singleton with name 'cfc'

2. Edit the `var nodes_map` in cfc.gd in the "Behaviour Constants" section, to point to your board and other container scenes (Deck, discard etc)

4. Edit the pile_names and hand_names arrays with the names of your respective piles (deck, discard etc) and hand(s).


### Card class

The below instructions will set up your game to use the `Card` class as a framework for card handling.

1. Extend your card root node's script, from the Card class. If your card scene's root node is not an Area2D, modify the CardTemplate to extend the correct node type

    `extends Card`

   This will allow you to keep your custom code clean, while benefiting from the framework functionality.

   It will also make it easy to upgrade your framework by just copying more recent versions of CardTemplate.gd.

4. If you're not using the provided CardTemplate.tcsn, then the following nodes inside CardTemplate.tcsn are mandatory. Place them in the same indentation and with the same name. Nodes with an asterisk next to their name can be modified to a different type but have to retain their name.
	* Area2D
	* CollisionShape2D
	* Control # Has to always be a Control-type node
		* Front # You can modify or remove children and change to another Control-type node
		* Back # You can modify or remove children (except Viewed) and change to another Control-type node
		    * CenterContainer/Viewed
		* Tokens and all children nodes
	* ManipulationButtons
	* all Tween nodes called "*Tween"
	* TargetLine and all children nodes


If you want a different setup, you will need to modify the relevant code yourself
### Hand Class

The Hand class retains cards face up in an organized fashion. Card which detect being in a Hand container, will always attempt to keep themselves sorted.

The below instructions will set up your game to use the `Hand` class as a framework for hand handling.

2. Extend your hand's script (attached to your Area2D root node) from the Hand class

   `extends Hand`

2. Connect your card-draw signal to the Hand node and make it call the `draw_card()` (see the Deck.tcsn node for a sample of such a signal)

4. If you're not using the provided Hand.tcsn, then the following nodes inside CardTemplate.tcsn are mandatory. Place them in the same indentation and with the same name. Nodes with an asterisk next to their name can be modified to a different type but have to retain their name.
	* Area2D
	* CollisionShape2D node
	* Control* (Has to always be a Control-type node)
	* ManipulationButtons
	* all Tween nodes called "Tween"


### Pile Class

The Pile class keeps child cards hidden and acts as a stack from which to pick or put out-of-play cards

The below instructions will set up your game to use the `Pile` class as a framework for pile handling.

2. Extend your pile's script (attached to your Area2D root node) from the Hand class

   `extends Pile`

1. If you're not using the provided Container.tcsn to instance new piles, then you need to add the following nodes. The indentation of the below points the hierarchy of the nodes you need to add, starting with scene root.
	* Area2D
	* CollisionShape2D node
	* Control* (Has to always be a Control-type node)
	* ManipulationButtons
	* all Tween nodes called "Tween"


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

The scripting engine relies on two gdscipt files, `ScriptingEngine.gd`, which contains all the scripting APIs for manipulating cards and `CardScriptDefinitions.gd` which contains a dictionary of all the scripts you've defined for your cards. Not only that, but if needed you can customize an individual card's script during runtime, which can make it behave different than other cards of the same name.

The game comes with some sample scripted cards which can be found under `res://src/custom/cards`. You can peruse the CardScripts to understand how they work.


## Provided features

* Tween animations that look good for card movements.
* Customizable card highlights
* Automatic focus-in on cards when moused over in-hand.
* Automatic re-arranging of hand as cards are added or removed.
* Drag & Drop
* Option for multiple hands and piles
* Piles of cards represent their size visually.
* Larger image of card when moving mouse cursor over it
* Pop-up buttons for predefined functions on cards and card containers
* Option to look inside the piles and choose cards to move out
* Cards can rotate on the table
* Cards can attach to other cards and move together as a group.
* Cards can target other cards with a draggable arrow (demo with right-mouse drag & drop)
* Can flip cards face-down and view them while in that state
* Can add tokens on cards
* Complete Card Text Scripting Capability

## Contributing

Please see the [Contribution Guide](contributing.md)

You can also join us on Discord with this invite code: https://discord.gg/AjZMFY7jD4

## Credits

Some initial ideas were taken from this excellent [Godot Card Game Tutorial video series](https://www.youtube.com/watch?v=WjT5sLMD7Kw). This framework uses some of the concepts but also attempts to create better quality code in the process.