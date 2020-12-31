extends Counters


func _ready() -> void:
	counters_container = $VBC
	value_node = "Value"
	needed_counters = {
		"credits": {
			"CounterTitle": "Available Credits: ",
			"Value": 100},
		"research":{
			 "CounterTitle": "Research: ",
			"Value": 0},
	}
	spawn_needed_counters()
