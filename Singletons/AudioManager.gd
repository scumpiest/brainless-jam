extends Node

enum AudioBus { Master, Music, Effects, Count }
const _audioBusStrings : Array[String] = [ "Master", "Music", "Effects" ]
var _indexLookup : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(_audioBusStrings.size() + AudioBus.Count)
	for bus : String in _audioBusStrings:
		_indexLookup.push_back(AudioServer.get_bus_index(bus))


func setVolume(bus : AudioBus, value : float) -> void:
	AudioServer.set_bus_volume_linear(_indexLookup[bus], value)
