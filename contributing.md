# Contribution Guide

So you want to help improve this project? We'll be glad to have you!

This document is meant to explain the expectations from our contributors.

## Keep your changes limited in scope.

If you send us a massive change with modification of hundreds of lines of code, which adds/removes/changes multiple functionalities at the same time, it's likely it will be rejected

This is because it's too difficult to parse too many changes at the same time, as you cannot tell which functionality each line edit is meant to support. 

Whenever you want to make a change, figure out the exact scope, and start by making a git branch:

    git checkout -b my-change-name

Then continue working on this branch and implement your scope and only that scope. If in the process you had another awesome idea for a new change, switch to the main branch (or stay in the same branch if it relies on the previous changes you did), then **make a new branch** and work on it from there.

This means that we can review the changes you did for each scope in isolation. This helps us understand better what you changed and prevents merge conflicts.

## Test your changes

We expect it goes without saying that you started Godot and you at least made sure it runs. But even then, a project such as this has a lot of moving parts and seemingly unrelated changes you do, can easily break other parts of the game you did not expect

This is where Unit and Integration tests come in. This Framework comes with [GUT](https://github.com/bitwes/Gut) preincluded. Before considering sending asking us to pull your code, you need to ensure all existing GUT tests work!

To do this, run the scene res://tests/tests.tcsn and press the play button. You should get no failures. If you do, your changes have changed some functionality unexpectedly and introduced a bug. You need to fix it before you sent to us, because we're going to check using the same process!

## Create tests for your changes

If you introducted new functionality, you need to adapt the existing unit or integration tests to test that it always works as expected. This will prevent anyone (including yourself) from breaking existing functionality in the future without noticing.

Take a look at existing tests and use them as template to write new tests for your new functionality. 

In case you're just tweaking existing functionality and things are expected to work different than before, it also means some existing tests will fail, but this should be expected. You're also expected to modify those tests to succeed with the changes you've done. Removing tests is not allowed. That's cheating! :D

## Comment your variables and functions

You will notice that our existing code is fairly well commented. At the minimum, any new class, function or variable you're adding to the framework should be documented in the same manner.

This is important because our comments are used to generate our documentation in the wiki. Not only do you help your fellow framework developers understand what you're adding, but you're making sure that users of the framework understand how to use it properly.

## Syntax

Make sure you follow the [Official Godot syntax guidelines](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_styleguide.html)

## Git and pull requests

When you want to submit code, you should send a pull request from the branch you've modified. Do not send us pull requests from your main branch!

**Before you do that though**,you need to squash all your commits into one larger commit. [You can use this handy guide for instructions](https://www.internalpointers.com/post/squash-commits-into-one-git)

