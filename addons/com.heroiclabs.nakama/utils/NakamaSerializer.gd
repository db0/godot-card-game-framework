extends Reference
class_name NakamaSerializer

static func serialize(p_obj : Object) -> Dictionary:
	var out = {}
	var schema = p_obj.get("_SCHEMA")
	if schema == null:
		return {} # No schema defined
	for k in schema:
		var prop = schema[k]
		var val = p_obj.get(prop["name"])
		if val == null:
			continue
		var type = prop["type"]
		var content = prop.get("content", TYPE_NIL)
		if typeof(content) == TYPE_STRING:
			content = TYPE_OBJECT
		var val_type = typeof(val)
		match val_type:
			TYPE_OBJECT: # Simple objects
				out[k] = serialize(val)
			TYPE_ARRAY: # Array of objects
				var arr = []
				for e in val:
					if typeof(e) != TYPE_OBJECT:
						continue
					arr.append(serialize(e))
				out[k] = arr
			TYPE_INT_ARRAY, TYPE_STRING_ARRAY: # Array of ints, bools, or strings
				var arr = []
				for e in val:
					if content == TYPE_BOOL:
						e = bool(e)
					if typeof(e) != content:
						continue
					arr.append(e)
				out[k] = arr
			TYPE_DICTIONARY: # Maps
				var dict = {}
				if content == TYPE_OBJECT: # Map of objects
					for l in val:
						if val_type != TYPE_OBJECT:
							continue
						dict[l] = serialize(val)
				else: # Map of simple types
					for l in val:
						if val_type != content:
							continue
						dict[l] = val
			_:
				out[k] = val
	return out

static func deserialize(p_ns : GDScript, p_cls_name : String, p_dict : Dictionary) -> Object:
	var cls : GDScript = p_ns.get(p_cls_name)
	var schema = cls.get("_SCHEMA")
	if schema == null:
		return NakamaException.new() # No schema defined
	var obj = cls.new()
	for k in schema:
		var prop = schema[k]
		var pname = prop["name"]
		var type = prop["type"]
		var required = prop["required"]
		var content = prop.get("content", TYPE_NIL)
		var type_cmp = type
		if typeof(type) == TYPE_STRING: # A class
			type_cmp = TYPE_DICTIONARY
		if type_cmp == TYPE_STRING_ARRAY or type_cmp == TYPE_INT_ARRAY: # A specialized array
			type_cmp = TYPE_ARRAY

		var content_cmp = content
		if typeof(content) == TYPE_STRING: # A dictionary or array of classes
			content_cmp = TYPE_DICTIONARY

		var val = p_dict.get(k, null)

		# Ints might and up being recognized as floats. Change that if needed
		if typeof(val) == TYPE_REAL and type_cmp == TYPE_INT:
			val = int(val)

		if typeof(val) == type_cmp:
			if typeof(type) == TYPE_STRING:
				obj.set(pname, deserialize(p_ns, type, val))
			elif type_cmp == TYPE_DICTIONARY:
				var v = {}
				for l in val:
					if typeof(content) == TYPE_STRING:
						v[l] = deserialize(p_ns, content, val[l])
					elif content == TYPE_INT:
						v[l] = int(val[l])
					elif content == TYPE_BOOL:
						v[l] = bool(val[l])
					else:
						v[l] = str(val[l])
				obj.set(pname, v)
			elif type_cmp == TYPE_ARRAY:
				var v
				match content:
					TYPE_INT, TYPE_BOOL: v = PoolIntArray()
					TYPE_STRING: v = PoolStringArray()
					_: v = Array()
				for e in val:
					if typeof(content) == TYPE_STRING:
						v.append(deserialize(p_ns, content, e))
					elif content == TYPE_INT:
						v.append(int(e))
					elif content == TYPE_BOOL:
						v.append(bool(e))
					else:
						v.append(str(e))
				obj.set(pname, v)
			else:
				obj.set(pname, val)
		elif required:
			obj._ex = NakamaException.new("ERROR [%s]: Missing or invalid required prop %s = %s:\n\t%s" % [p_cls_name, prop, p_dict.get(k), p_dict])
			return obj
	return obj


###
# Compatibility with Godot 3.1 which does not expose String.http_escape
###
const HEX = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]

static func escape_http(p_str : String) -> String:
	var out : String = ""
	for o in p_str:
		if (o == '.' or o == '-' or o == '_' or o == '~' or
			(o >= 'a' and o <= 'z') or
			(o >= 'A' and o <= 'Z') or
			(o >= '0' and o <= '9')):
			out += o
		else:
			for b in o.to_utf8():
				out += "%%%s" % to_hex(b)
	return out

static func to_hex(p_val : int) -> String:
	var v := p_val
	var o := ""
	while v != 0:
		o = HEX[v % 16] + o
		v /= 16
	return o
