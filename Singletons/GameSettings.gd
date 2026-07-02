extends Node

var MASTER_VOLUME : float = 1.0
var MUSIC_VOLUME : float = 1.0
var EFFECTS_VOLUME : float = 1.0


const _saveFilePath : String = "user://gameSettings.json"



class GodotProperty:
	var name: String
	var type: int
	var hint: int
	var hint_string: String
	var usage: PropertyUsageFlags
	
	# Map a raw Dictionary safely to this instance
	func _init(dict: Dictionary):
		name = dict.get("name", "")
		type = dict.get("type", TYPE_NIL)
		hint = dict.get("hint", PropertyHint.PROPERTY_HINT_NONE)
		hint_string = dict.get("hint_string", "")
		usage = dict.get("usage", PropertyUsageFlags.PROPERTY_USAGE_DEFAULT)


func getProperties(filter: PropertyUsageFlags) -> Array[GodotProperty]:
	var props : Array[GodotProperty] = []
	for property in get_property_list():
		var prop := GodotProperty.new(property)
		if prop.usage & filter:
			props.push_back(prop)
	
	return props


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loadFromFile()
	
	AudioManager.setVolume(AudioManager.AudioBus.Master, MASTER_VOLUME)
	AudioManager.setVolume(AudioManager.AudioBus.Music, MUSIC_VOLUME)
	AudioManager.setVolume(AudioManager.AudioBus.Effects, EFFECTS_VOLUME)


func loadFromFile() -> void:
	if not FileAccess.file_exists(_saveFilePath):
		print("No current settings file, creating")
		saveToFile()
		return

	var saveFile: FileAccess = FileAccess.open(_saveFilePath, FileAccess.READ)
	if saveFile == null:
		print("Failed to load file: %s - %d" % [_saveFilePath, FileAccess.get_open_error()])
		return

	var saveDataStr : String = saveFile.get_as_text()
	saveFile.close()
	assert(saveDataStr)
	
	var saveData : Dictionary = JSON.parse_string(saveDataStr)
	assert(saveData)
	
	for prop : GodotProperty in getProperties(PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE):
		if saveData.has(prop.name):
			set(prop.name, saveData.get(prop.name, type_convert(null, prop.type)))
			print("Game settings loaded: %s = %f" % [prop.name, get(prop.name)]) 


func saveToFile() -> void:
	var saveFile : FileAccess = FileAccess.open(_saveFilePath, FileAccess.WRITE)
	assert(saveFile)
	
	var saveData : Dictionary = {}
	for prop : GodotProperty in getProperties(PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE):
		saveData[prop.name] = JSON.stringify(get(prop.name))
		print("Game setting saving: %s = %f" % [prop.name, get(prop.name)])
	
	var saveString : String = JSON.stringify(saveData)
	assert(saveString)

	saveFile.store_string(saveString)
	saveFile.close()
	