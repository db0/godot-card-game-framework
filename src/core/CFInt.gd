# Card Gaming Framework global Internal Constants
#
# This class contains constants which are referenced by various classes.
# This avoids cyclic dependencies.
#
# These constants are not expected to be tweaked by developers who need
# to be able to upgrade the CGF.
class_name CFInt
extends Reference

# The types of ScriptingEngine executions we can have
#
# * NORMAL is executing all tasks, except "is_else" tasks
# * COST_CHECK is checking if the tasks which are marked as "is_cost" can be
# fulfilled, but does not actually execute them
# * ELSE executes only tasks which are marked "is_else". This execution only
# Takes place when a COST_CHECK run discovers it cannot fulfil
# a task marked as such.
enum RunType{
	NORMAL
	COST_CHECK
	ELSE
}
# The focus style used by the engine
# * SCALED means that the cards simply scale up when moused over in the hand
# * VIEWPORT means that a larger version of the card appears when mousing over it
# * BOTH means SCALED + VIEWPORT
enum FocusStyle {
	SCALED
	VIEWPORT
	BOTH
	BOTH_INFO_PANELS_ONLY
}
# Options for displacing choosing which of the [CardContainer]s
# sharing the same anchor to displace more.
# * LOWER: The CardContainer with the lowest index will be displaced more
# * HIGHER: The CardContainer with the highest index will be displaced more
# Do not mix containers using both of these settings, unless the conflicting
# container's OverlapShiftDirection is set to "NONE"
enum IndexShiftPriority{
	LOWER
	HIGHER
}
# Options for displacing [CardContainer]s sharing the same anchor
# * NONE: This CardContainer will never be displaced from its position
# * UP: This CardContainer will be displaced upwards. Typically used when
#	this container is using one of the bottom anchors.
# * DOWN: This CardContainer will be displaced downwards.Typically used when
#	this container is using one of the top anchors.
# * LEFT: This CardContainer will be displaced leftwards. Typically used when
#	this container is using one of the right anchors.
# * RIGHT: This CardContainer will be displaced rightwards.Typically used when
#	this container is using one of the left anchors.
enum OverlapShiftDirection{
	NONE
	UP
	DOWN
	LEFT
	RIGHT
}
