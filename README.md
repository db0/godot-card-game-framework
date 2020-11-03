# Godot Card Gaming Framework 0.7

This framework is meant to provide well-designed, statically-typed, and well-commented classes which you can plug into any potential card game to provide a polished way to handle typical behaviour expected from cards in a game.

Pull requests are more than welcome ;)

## Installation

First of all, make sure your project's window stretch mode is set to either 'disabled' or 'viewport'

### Card class

The below instructions will set up your game to use the `Card` class as a framework for card handling.

1. Copy the CardTemplate.gd and Hand.gd in an appropriate location in your project.

   The CardTemplate.tcsn file is optional, but if you're looking for a design template for your cards, 
   feel free to use it by instancing child scenes based on it.

2. Extend your card node's script, from the Card class

    `extends Card`

   This will allow you to keep your custom code clean, while benefiting from the framework functionality. 
  
   It will also make it easy to upgrade your framework by just copying more recent versions of CardTemplate.gd.

4. If you're not using the provided CardTemplate.tcsn, add a tween node called "Tween" to the root of your card scene.

5. Edit the `var nodes_map` in cfc_config.gd in the "Behaviour Constants" section, to point to your board and various container scenes (Deck, discard etc)

6. Add cfc_config.gd as an autoloaded singleton with name 'cfc_config'

### Hand Class

The below instructions will set up your game to use the `Hand` class as a framework for hand handling.

1. Add a Node2D as a child node to where you want your hand to appear, then make sure that its script extends the Hand class.

    `extends Hand`

2. Connect your card-draw signal to the Hand node and make it call the `draw_card()` (see the Deck.tcsn node for a sample of such a signal)

### Unit Testing

Do the following if you want to use/import the provided unit tests

1. [install Gut](https://github.com/bitwes/Gut/wiki/Install) and do the relevant setup, if you don't have it already.
2. If you followed the standard Gut instructions, you should have already have created the tests folder, copy the test_*.gd from /tests/unit inside your own `res://tests/unit`.
3. Edit TestVars.gd and modify the boardScene const to point to the root board (i.e. where the cards are played) of your game. 
4. You need to either copy and use (load directly ot set it as an extension class to your own board scene) the provided Board.tscn to your own resources, or you need to copy the code inside Board.tcsn into your own board (at there's necessary Unit Testing code in there)

## Easy Customation

The classes provide some easy customization options, such as how the card move, where they appear etc
Check the "Behaviour Constants" header at the start of the cfc_config node.
For more specific customization, you'll need to modify manually


## Provided features

* Tween animations that look good for card movements.
* Automatic zoom-in on cards when moused over.
* Automatic re-arranging of hand as cards are added or removed.
* Drag & Drop to the table

## Credits

Many ideas were taken from this excellent [Godot Card Game Tutorial video series](https://www.youtube.com/watch?v=WjT5sLMD7Kw). This framework uses some of the concepts but also attempts to create better quality code in the process.