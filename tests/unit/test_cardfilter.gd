extends "res://tests/UTcommon.gd"

var cards := []
var comparison_dict : Dictionary

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	comparison_dict =  {
		"Cost": 1,
		"Power": "X",
		"Type": "Green"
	}
#	var confirm_return = setup_board()
#	if confirm_return is GDScriptFunctionState: # Still working.
#		confirm_return = yield(confirm_return, "completed")

func test_init() -> void:
	var cf = CardFilter.new('Type', 'Blue')
	assert_eq(cf.property, "Type",
			"CardFilter property init property")
	assert_eq(cf.filter, "Blue",
			"CardFilter value init property")
	assert_eq(cf.comparison, "eq",
			"CardFilter comparison init property")
	assert_false(cf.compare_int_as_str,
			"CardFilter compare_int_as_str init property")

func test_comparison_int_as_string_convert() -> void:
	var cf = CardFilter.new('Cost', 1, 'ge', true)
	assert_eq(cf.property, "Cost",
			"CardFilter property init property")
	assert_eq(cf.filter, 1,
			"CardFilter value init property")
	assert_eq(cf.comparison, "eq",
			"CardFilter comparison init property")
	assert_true(cf.compare_int_as_str,
			"CardFilter compare_int_as_str init property")

func test_string_eq_comparison() -> void:
	var cf = CardFilter.new('Type', 'Blue', 'eq')
	assert_false(cf.check_card(comparison_dict),
			"False when strings not equal")
	comparison_dict.Type = 'Blue'
	assert_true(cf.check_card(comparison_dict),
			"True when strings equal")

func test_string_ne_comparison() -> void:
	var cf = CardFilter.new('Type', 'Blue', 'ne')
	assert_true(cf.check_card(comparison_dict),
			"True when strings not equal")
	comparison_dict.Type = 'Blue'
	assert_false(cf.check_card(comparison_dict),
			"False when strings equal")

func test_int_eq_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'eq')
	assert_false(cf.check_card(comparison_dict),
			"False when ints not equal")
	comparison_dict.Cost = 2
	assert_true(cf.check_card(comparison_dict),
			"True when ints equal")

func test_int_ne_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'ne')
	assert_true(cf.check_card(comparison_dict),
			"True when ints not equal")
	comparison_dict.Cost = 2
	assert_false(cf.check_card(comparison_dict),
			"False when ints equal")

func test_int_lt_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'lt')
	assert_true(cf.check_card(comparison_dict),
			"True when int lower than")
	comparison_dict.Cost = 2
	assert_false(cf.check_card(comparison_dict),
			"False when int equal")
	comparison_dict.Cost = 3
	assert_false(cf.check_card(comparison_dict),
			"False when higher than")

func test_int_gt_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'gt')
	assert_false(cf.check_card(comparison_dict),
			"False when int lower than")
	comparison_dict.Cost = 2
	assert_false(cf.check_card(comparison_dict),
			"False when int equal")
	comparison_dict.Cost = 3
	assert_true(cf.check_card(comparison_dict),
			"True when higher than")

func test_int_ge_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'ge')
	assert_false(cf.check_card(comparison_dict),
			"False when int lower than")
	comparison_dict.Cost = 2
	assert_true(cf.check_card(comparison_dict),
			"False when int equal")
	comparison_dict.Cost = 3
	assert_true(cf.check_card(comparison_dict),
			"True when higher than")

func test_int_le_comparison() -> void:
	var cf = CardFilter.new('Cost', 2, 'le')
	assert_true(cf.check_card(comparison_dict),
			"True when int lower than")
	comparison_dict.Cost = 2
	assert_true(cf.check_card(comparison_dict),
			"False when int equal")
	comparison_dict.Cost = 3
	assert_false(cf.check_card(comparison_dict),
			"False when higher than")

func test_str_bad_comparison_fallback() -> void:
	var cf = CardFilter.new('Abilities', 2, 'gt')
	assert_eq(cf.comparison, "eq",
			"Comparison fallback property")
	assert_typeof(cf.filter, TYPE_STRING)

func test_int_bad_comparison_fallback() -> void:
	var cf = CardFilter.new('Cost', '2', 'ge')
	assert_eq(cf.comparison, "ge",
			"Comparison stayed correct")
	assert_typeof(cf.filter, TYPE_INT)

func test_string_number_to_string_eq_comparison_with_string_filter_considered_0() -> void:
	var cf = CardFilter.new('Power', 'X', 'eq')
	assert_true(cf.check_card(comparison_dict),
			"True when equal")
	comparison_dict.Power = 3
	assert_false(cf.check_card(comparison_dict),
			"False when ne int")
	comparison_dict.Power = 'U'
	assert_false(cf.check_card(comparison_dict),
			"False when ne string")

func test_string_number_to_string_ne_comparison_with_string_filter_considered_0() -> void:
	var cf = CardFilter.new('Power', 'X', 'ne')
	assert_false(cf.check_card(comparison_dict),
			"False when equal")
	comparison_dict.Power = 3
	assert_true(cf.check_card(comparison_dict),
			"True when not equal int")
	comparison_dict.Power = 'U'
	assert_true(cf.check_card(comparison_dict),
			"True when not equal string")

func test_string_number_to_string_eq_comparison_with_string_filter_not_considered_0() -> void:
	var cf = CardFilter.new('Power', 'U', 'eq')
	assert_false(cf.check_card(comparison_dict),
			"False when ne equal")
	comparison_dict.Power = 3
	assert_false(cf.check_card(comparison_dict),
			"False when ne int")
	comparison_dict.Power = 'U'
	assert_true(cf.check_card(comparison_dict),
			"True when eq string")

func test_string_number_to_string_ne_comparison_with_string_filter_not_considered_0() -> void:
	var cf = CardFilter.new('Power', 'U', 'ne')
	assert_true(cf.check_card(comparison_dict),
			"True when equal")
	comparison_dict.Power = 3
	assert_true(cf.check_card(comparison_dict),
			"True when not equal int")
	comparison_dict.Power = 'U'
	assert_false(cf.check_card(comparison_dict),
			"False when not equal string")

func test_int_to_int_string_comparison() -> void:
	var cf = CardFilter.new('Power', 2, 'le')
	comparison_dict.Power = '1'
	assert_true(cf.check_card(comparison_dict),
			"Int-String comparison handled property on le")
	comparison_dict.Power = '2'
	assert_true(cf.check_card(comparison_dict),
			"Int-String comparison handled property on le")
	comparison_dict.Power = '3'
	assert_false(cf.check_card(comparison_dict),
			"Int-String comparison handled property on le")

func test_null_to_int_comparison() -> void:
	var cf = CardFilter.new('Power', null, 'le')
	comparison_dict.Power = 1
	assert_false(cf.check_card(comparison_dict),
			"Null-int comparison handled property")
	comparison_dict.Power = '2'
	assert_false(cf.check_card(comparison_dict),
			"Null-int comparison handled property")
	comparison_dict.Power = 'X'
	assert_false(cf.check_card(comparison_dict),
			"Null-int comparison handled property")

func test_array_eq_comparison() -> void:
	var cf = CardFilter.new('Tags', 'GUT 3', 'eq')
	assert_false(cf.check_card(comparison_dict),
			"False when array element does not exist")
	comparison_dict.Tags = ["GUT 1", "GUT 3"]
	assert_true(cf.check_card(comparison_dict),
			"True when array element exists")

func test_array_ne_comparison() -> void:
	var cf = CardFilter.new('Tags', 'GUT 3', 'ne')
	assert_true(cf.check_card(comparison_dict),
			"True when array element does not exist")
	comparison_dict.Tags = ["GUT 1", "GUT 3"]
	assert_false(cf.check_card(comparison_dict),
			"False when array element exists")
