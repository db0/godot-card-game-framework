extends Reference
class_name NakamaStorageObjectId

# The collection which stores the object.
var collection : String

# The key of the object within the collection.
var key : String

# The user owner of the object.
var user_id : String

# The version hash of the object.
var version : String

func _init(p_collection, p_key, p_user_id = "", p_version = ""):
	collection = p_collection
	key = p_key
	user_id = p_user_id
	version = p_version

func as_delete():
	return NakamaAPI.ApiDeleteStorageObjectId.create(NakamaAPI, {
		"collection": collection,
		"key": key,
		"version": version
	})

func as_read():
	return NakamaAPI.ApiReadStorageObjectId.create(NakamaAPI, {
		"collection": collection,
		"key": key,
		"user_id": user_id
	})
