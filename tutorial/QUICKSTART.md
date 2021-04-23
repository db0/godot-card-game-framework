# Godot Card Game Framework Quick Start Guide

**Written for v1.9**

This guide is meant to take you through using the Card Game Framework (CGF from now on) for the first time in a simple step-by-step approach, starting from brand a new project.

Hopefully by the end of this tutorial you'll have a better idea of what goes where and how things connect to each other.

Think of this as the "Hello World" instructions for this Framework.


## Step 1: Create new project and setup to use CGF

In this part, we'll create a new project which is going to use the existing CGF demonstration scenes as its baseline.

1. Use Godot to create a new project.
2. Download the latest version of the CGF and extract all directories into your project's root folder. 
3. Go to Project > Project Setting > Autoload. Press the browse button and search for `res://src/core/CFControl`. Type "cfc" in the "Node name:" field.
4. Go to Project > Project Settings > General > Application > Run and next to the Main Scene type `res://src/custom/CGFMain.tscn`
5. Close Project Settings and press F5 to play the new project. A basic demo setup will appear and you'll be able to draw cards, move them around etc.

## Step 2: Prepare for customization

In order to be able to upgrade this framework in the future without losing your own customizations, it's strongly suggested you work off inherited scenes. We're going to set that up now, using some of the existing demo scenes as templates as well.

1. Create a new directory to store your own game's definition. Let's put it in `res://src/new_card_game`
1. find and Right click on `res://src/custom/CGFBoard.tscn` and select "Duplicate...". As a name, write "Board.tcsn". 
1. find and Right click on `res://src/custom/CGFBoard.gd` and select "Duplicate...". As a name, write "Board.gd". 
1. find and Right click on `res://src/custom/CGFInfoPanel.tcsn` and select "Duplicate...". As a name, write "InfoPanel.tcsn". 
1. From the filesystem tab, drag and drop Board.tcsn and Board.gd, InfoPanel.tcsn and SP.gd inside `res://src/new_card_game`
1. Double click `res://src/new_card_game/Board.tcsn` to open it. Right click on the root node and "Attach Script". then in the path either nagivate, or type `res://src/new_card_game/Board.gd`
1. find and Right click on `res://src/core/Main.tscn` and select "New Inherited Scene". A new unsaved scene will open.
1. In the inspector, under "Script Variables", click on "[empty]" next to Board Scene, then "load" then navigate to your `res://src/new_card_game/Board.tcsn`
1. In the inspector, under "Script Variables", click on "[empty]" next to "Info Panel Scene", then "load" then navigate to your `res://src/new_card_game/InfoPanel.tcsn`
1. Save the unsaved scene as `res://src/new_card_game/Main.tcsn`
1. Press play scene (F6). If you did everything above right, an identicaly demo should run off of your `res://src/new_card_game/` scenes.

We're halfway there, we have now created an inherited Main.tcsn scene which we can customize and we have our own Board.tcsn to modify.

The board is still using a lot of the demo code inside `res://src/custom/` which we need to be able to customize for our own game. 

1. Find and Right click on `res://src/custom/CGFDeck.gd` and select "Duplicate...". As a name, write "Deck.gd". 
2. From the filesystem tab, drag and drop "Deck.gd" inside `res://src/new_card_game`
3. Open Board.tcsn and in the scene view, right click on the "Deck" node, then "Attach Script", then in the path either nagivate, or type `res://src/new_card_game/Deck.gd`
4. Click on the Deck node. In the inspector, select the "Placement" that suits your game.

Follow the above procedure also for "Discard.gd" and "Hand.gd". 

**Note:** You could achieve the same effect as above by simply detaching the old scripts, then attaching new scripts extending Pile or Hand respectively to your Deck, Discard, or Hand node. The 4 steps above though, also provide some common starting functions for your game such as card draw on which you can build upon.

Now you can add custom code to your Deck, Discard and Hand classes. Press F6 again while on the Main scene to ensure all went OK until now

Now let's make sure we have a card template dedicated to our own game on which we can build upon

1. Find and Right click on `res://src/core/CardTemplate.tscn` and select "New Inherited Scene". A new unsaved scene will open.
1. Find and Right click on `res://src/custom/CGFCardManipulationButton.tscn` and select "Duplicate...". As a name, write "CardManipulationButton.tscn". 
1. Find and Right click on `res://src/custom/CGFManipulationButtons.gd` and select "Duplicate...". As a name, write "ManipulationButtons.gd". 
1. In the FileSystem tab,  drag and drop "CardManipulationButton.tscn" and "ManipulationButtons.gd" inside `res://src/new_card_game`
1. On the Scene tab, right-click on the ManipulationButton node, then "Attach Script" then in the path either nagivate, or type `res://src/new_card_game/ManipulationButtons.gd`
1. On the Scene tab, click on the ManipulationButton node, then in the inspector click on "[empty]" next to Manipulation Button, then "load" then navigate to your `res://src/new_card_game/CardManipulationButton.tscn`
1. Find and Right click on `res://src/custom/CGFCardBack.tscn` and select "Duplicate...". As a name, write "CardBack.tscn". 
1. Find and Right click on `res://src/custom/CGFCardFront.tscn` and select "Duplicate...". As a name, write "CardFront.tscn". 
1. Find and Right click on `res://src/custom/CGFCardFront.gd` and select "Duplicate...". As a name, write "CardFront.gd". 
1. In the FileSystem tab, drag and drop"CardBack.tscn", "CardFront.tscn"  and "CardFront.gd" inside `res://src/new_card_game`
1. Double click `res://src/new_card_game/CardFront.tcsn` to open it. Right click on the root node and "Attach Script". then in the path either nagivate, or type `res://src/new_card_game/CardFront.gd`
1. Click on the CardTemplate.tcsn root node. 
1. In the inspector click on "[empty]" next to Card Back Design, then "load" then navigate to your `res://src/new_card_game/CardBack.tcsn`
1. In the inspector click on "[empty]" next to Card Front Design, then "load" then navigate to your `res://src/new_card_game/CardFront.tcsn`
1. Save the unsaved Scene as `res://src/new_card_game/CardTemplate.tcsn`

You'll notice again we're duplicating some of the demo code.  We could easily do the same by simply creating new scenes and scripts from scratch, but for a quickstart, this provides us with similar functionality as the demo, which we can build upon.
 
We have now created an inherited card scene as well as custom card back card front and manipulation button scenes which we can modify to fit our game look. 

However typically the games don't have only one card, so we need to let our game know where our game stores its custom cards.  At the moment, the Framework is configured to look inside `res://src/custom`, but we cant to make sure it's looking inside our own folder.

1. Move `res://src/custom/CFConst.gd` to `res://src/new_card_game/`
1. Create a new folder `res://src/new_card_game/cards`
1. Create a new folder `res://src/new_card_game/cards/sets`
1. In the filesystem tab, navigate to `res://src/custom/cards`.
1. Move "CardConfig.gd" and "CustomScripts" inside `res://src/new_card_game/cards`
1. In the filesystem tab, navigate to `res://src/custom/cards/sets`.
1. Edit `res://src/new_card_game/CFConst.gd`
1. Find the line `const PATH_CUSTOM := "res://src/custom/"` and modify it to `const PATH_CUSTOM := "res://src/new_card_game/"`

Now our game will be looking for custom card configurations (Card Definitions, Card Scripts etc) inside our new directory structure.

Press Run Scene (F6) on our `res://src/new_card_game/Main.tcsn` scene. The same demo board should appear, but the deck will be empty. This is because we have not defined any cards yet. But before we do that, we need to create our new card Types. We'll do that in the next section.

If everything went OK, we can now use our new Main scene. Open your project settings and Change Application > Run > Main Scene to `res://src/new_card_game/Main.tcsn`. Run the whole project with F5 to verify

## Step 3: Create a new card type

In this part, we'll create our first new card type which will serve as the baseline for a specific subset of cards.

For this demonstration, let's create a "creature" type card.

1. In the Godot Filesystem view, navigate to `res://src/new_card_game/`
1. Right-click on `CardFront.tcsn` and select "New Inherited Scene". A new tab will open on the top called "[unsaved]". Press "F1" to ensure you're on the 2D view. You should see a grey card. This is the card front baseline coming from the CGF. We're now going to modify that to fit our purposes.
1. In the Godot Scene tab, double-click on "Front" to rename the scene root. Let's rename it to "CreatureFront" to remind ourselves what this is when working on our scenes. It's not otherwise important.
1. On the Inspector find and expand custom styles. Then click on the arrow next to StyleBox and select "Make Unique".
1. Click on the "StyleBox" label, to expand its properties
1. Click on the "Bg Color". The colour picker will appear. Select a background colour you want to use for your creature cards.
1. Save the scene as `res://src/new_card_game/cards/Creature.tcsn`
1. The basic card template has most of the information a creature would need, but what would a creature be without some Health. Let's add this now.
	Right click on HB > Add Child Node > search for "Label" and add it. The new label node will appear under the "Power" node.
1. Double click it to rename it to "Health". You can add text to see how it looks. If you cannot see it against the background colour, you will need to adjust the font. Let's provide a setup which should work with any background colour now:
1. With Health selected, in the inspector expand "Custom Fonts". Click on "[empty]" and select "New Dynamic Font".
1. Under "Font" expand settings. Put "Outline size" to 2 and "Outline color" to black. Check "use filter". White fonts with black outline should be visible against any background.
1. Click on the "Dynamic Font" dropdown to open its properties. Click on "Font". Click on "[empty]" next to Font Data. Select "load". If you've copied the "fonts" directory into your project, browse into `res://src/fonts` and select xolonium. Otherwise load any other font file you would like.
1. In the inspector for the "Health" label, find and expand the "rect" properties. Adjust the min_size of y to 13. This defines the maximum amount of vertical space our Health text should take before we start shrinking
	the label text to compensate
1. Since we're not creating a completely different front, we can just extend the existing default front script we're using for our game. Right click on the root node (should be called "Front") And select "extend script". A new window will popup will the script name to save. save it as `res://src/new_card_game/cards/CreatureFront.gd`.
	![Extend Card Script](3.extend_creature_front_script.png)
1. The new script will open. Add the text to the `_ready()` method as below
```
func _ready() -> void:
	card_labels["Health"] = $Margin/CardText/HB/Health
```
We have now mapped the new label node for our new card type, so that it can be found by our code. 
1. Save the Scene as `res://src/new_card_game/cards/CreatureFront.tcsn`
1. Right-click on `res://src/new_card_game/CardTemplate.tcsn` and select "New Inherited Scene". A new tab will open on the top called "[unsaved]". 
1. In the Godot Scene tab, double-click on "Card" to rename the scene root. Let's rename it to "Creature" to remind ourselves what this is when working on our scenes. It's not otherwise important.
1. In the root node inspector, click on the arrow next to Card Front Design > Load, then navigate and select `res://src/new_card_game/cards/CreatureFront.tcsn`
1. Press Ctrl+S to save our new scene as `res://src/new_card_game/cards/Creature.tcsn`. We now have our new card type scene template, but our game is not configuration to populate it just yet.


14. Open `res://new_card_game/card/CardConfig.gd`. This is where we specify what kind of information each label adds. Since the health of each creature is just a number, we'll add it as a number.
15. Edit `PROPERTIES_NUMBERS` and modify the array definition look like this

```
const PROPERTIES_NUMBERS := ["Cost","Power","Health"]
```


Now our creature template is ready to use.

## Step 4: Define a new card of the new type.

In this part, we'll define our card using a simply json format which will automatically create that card when we request that card name to be added.

1. Make a copy of `res://src/custom/cards/sets/SetDefinition_Demo1.gd` as `res://src/new_card_game/cards/sets/SetDefinition_Core.gd`
1. Make a copy of `res://src/custom/cards/sets/SetScripts_Demo1.gd` as `res://src/new_card_game/cards/sets/SetScripts_Core.gd`

These 2 steps are not strictly necessary, but it will give us some preconstructed dictionaries to modify later.

1. Edit `res://src/new_card_game/cards/sets/SetDefinition_Core.gd`
1. You should see two cards defined coming from the Framework Demo. We're going to remove them and define two creatures instead.
1. Modify the contents as so:
```
extends Reference

const SET = "Core Set"
const CARDS := {
	"Battle Beast": {
		"Type": "Creature",
		"Tags": ["Brutal", "Slow"],
		"Requirements": "",
		"Abilities": " ",
		"Cost": 2,
		"Power": 3,
		"Health": 3,
	},
	"Beast in Black": {
		"Type": "Creature",
		"Tags": ["Fast", "Flanking"],
		"Requirements": "Cannot be played on first turn",
		"Abilities": " ",
		"Cost": 1,
		"Power": 2,
		"Health": 1,
	},
}
```

Since you're reusing the CGFBoard.tcsn demonstration code, the new cards will automatically be included in the starting deck. Try it out now! 

Press F5 and draw some cards. Your "Beast" cards should be the only options.

Congratulations, you have now created your own customized workspace, defined your first card type, and created your first cards to use it!

![Success](4.end-creature-in-game.png)

Hopefully this will give you a basic idea of where things are. Continue exploring and changing things and you should be able to customize the framework to your needs in no-time.

Have fun!

## Addendum 1: Making it look nicer

You may think the bottom of the card is now a bit crowded. It might ever cause Health to overflow the card size. It might better if we just displayed the numerical value, and instead separated them via a "/".

How would you achieve that?
* **Hint:** Try reducing or removing the "Health" and "Power" entry from `res://src/new_card_game/CardFront.gd`. What happens to the size of the label font in runtime now?
* **Hint:** Check what happens if you move "Power" and "Health" from CardConfig.PROPERTIES_NUMBERS to CardConfig.PROPERTIES_STRINGS.
* Think how you could modify the node layout of Health and Power so that they are together in own HBoxContainer and separated by a new label having just the "/" text. You would also need to adjust their mapping in `_init_front_labels()` in the Creature.gd. How?

## Addendum 2: How Is Babby Formed?

If you're wondering how the Initial cards you see starting in the deck are added, this is all defined inside `res://src/new_card_game/Board.gd`. Inside `_ready()` you'll find a call to `load_test_cards()` which loads the deck with a random selection of cards among all those defined. This is why your "Beasts" magically appeared in the deck without you having to do anything else after defining it. Your game should of course include some logic in creating, storing and loading decks instead of relying on random chance. But this is currently outside the scope of this guide.

## Addendum 3: Core Concepts

The CGF tries to standardize some standard terms in order to keep track of what we're talking about.

* **Card:** A card is the core concept of our card game. In CGF, the Card class holds the logic for manipulating and moving card scenes around.
* **CardContainer:** As understood from the name, this is a container which is meant to hold cards. This term is a supergroup which contains both piles and hands
* **Hand:** A CardContainer which is meant to hold cards face up, and oriented in a way that they're all visible to the player.
* **Pile:** A CardContainer which is meant to hold cards stacked on top of each other. The deck and discard pile would be Piles.
* **Board:** The play area where cards can be placed and where the main game happens.
* **Manipulation Button:** A button which appears on a Card or CardContainer when you mouse over it. Code can be attached to it to do practically anything, but they tend to manipulate the object they're attached to in some way.
* **Token:** A counter that goes on a card to track and measure various changes as dictated by the game rules. For example a token might track "extra power" on a card.
* **Counter:** A counter that is tracked in some GUI element that refers to the game as a whole. For example a counter might track "player health".