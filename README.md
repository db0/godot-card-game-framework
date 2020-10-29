# Godot Card Gaming Library

This library is meant to provide well-designed, statically-typed, and well-commented classes which you can plug into any potential card game to provide a polished way to handle typical behaviour expected from cards in a game.

Pull requests are more than welcome ;)

## Installation

Simply copy the CardTemplate.gd and Hand.gd in an appropriate location in your project.

The CardTemplate.tcsn file is optional, but if you're looking for a design template for your cards, feel free to use it by instancing child scenes based on it.

Now simply extend your card node's script, from the Card class
    extends Card
This will allow you to keep your custom code clean, while benefiting from the library functionality
It will also make it easy to upgrade your library by just copying more recent versions of CardTemplate.gd
Once done, connect your card node's `mouse_entered()` and `mouse_exited()` signals to your card template's script.

Likewise, to use the provided Hand library, add a Node2D as a child node to where you want your hand to appear, then make sure that its script extends the Hand class.
Once done, connect your card-draw signal to the Hand node and make it call the `draw_card()` function.

Finally, make sure your project's window stretch mode is set to either 'disabled' or 'viewport'

## Easy Customizing

The classes provide some easy customization options, such as the location of your cards on the table etc.
Check the "Behaviour Constants" header at the start of the code.
For more specific customization, you'll need to modify manually


## Provided features

* Tween animations that look good for card movements.
* Automatic zoom-in on cards when moused over.
* Automatic re-arranging of hand as cards are added or removed.

## Credits

Many ideas were taken from this excellent [Godot Card Game Tutorial video series](https://www.youtube.com/watch?v=WjT5sLMD7Kw). This library uses some of the concepts but also attempts to create better quality code in the process.