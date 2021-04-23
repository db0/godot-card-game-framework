extends Reference
class_name NakamaLogger

enum LOG_LEVEL {NONE, ERROR, WARNING, INFO, VERBOSE, DEBUG}

var _level = LOG_LEVEL.ERROR
var _module = "Nakama"

func _init(p_module : String = "Nakama", p_level : int = LOG_LEVEL.ERROR):
	_level = p_level
	_module = p_module

func _log(level : int, msg):
	if level <= _level:
		if level == LOG_LEVEL.ERROR:
			printerr("=== %s : ERROR === %s" % [_module, str(msg)])
		else:
			var what = "=== UNKNOWN === "
			for k in LOG_LEVEL:
				if level == LOG_LEVEL[k]:
					what = "=== %s : %s === " % [_module, k]
					break
			print(what + str(msg))

func error(msg):
	_log(LOG_LEVEL.ERROR, msg)

func warning(msg):
	_log(LOG_LEVEL.WARNING, msg)

func info(msg):
	_log(LOG_LEVEL.INFO, msg)

func verbose(msg):
	_log(LOG_LEVEL.VERBOSE, msg)

func debug(msg):
	_log(LOG_LEVEL.DEBUG, msg)
