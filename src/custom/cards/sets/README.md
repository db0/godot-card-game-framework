Files starting with `SetScripts_` contains the definitions of all card scripts
defined in your game, set by set.

For reference: One single card manipulation is called a "task".

Everything is defined in the `scripts` dictionary inside `get_scripts()`
where the key is each card"s name.
This means that cards with the same name have the same scripts!

Not only that, but the cards can handle different scripts, depending on
where the are when the scripts are triggered (hand, board, pile etc).

The format for each card is as follows:
* First key is the card name in plaintext. At it would appear
	in the card_name variable of each card.
* Inside that is a dictionary based on triggers. Each trigger specified what causes the script to fire. 
	The default one is "manual" which triggers when the player double-clicks the card.
	You can see the list of triggers in [cfc.SignalPropagator.known_card_signals](https://github.com/db0/godot-card-gaming/wiki/CardFrameworkConfiguration#known_card_signals)
* Inside is a dictionary based on card states, where each key is the container
	from which the scripts will execute. So if the key is "board", then
	the scripts defined in that dictionary, will be executed only while
	the card in on the board (based on its state).
* Inside the state dictionary, is an array which contains one dictionary
	per individual task. The tasks will execute in the order
	they are defined in that list.
* Each task dictionary has many possible keys depending on its type,
	but also a few mandatory ones. 

Please see the documentation of the [ScriptTask](ScriptTask) which goes into details for each key the dictionary will accept

* Constants starting with `KEY_` are used as keys in card script definitions. They specify how an individual task should behave.
* Constants starting with `FILTER_` are also used as keys in card script definitions, but they are only relevant for scripts which are triggered automatically, or when looking up targets.
* Constants starting with `TRIGGER_` are sent by card signals as keys in a dictionary. The specify what the values of the task that triggered the script are. They are checked against the relevant `FILTER_` values.

An exception to the above is when the name is "custom_script".
In that case you don't need any other keys. The complete definition should
be in CustomScripts.gd