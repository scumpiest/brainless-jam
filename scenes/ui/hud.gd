extends CanvasLayer

@onready var _resource_label: Label = $ResourcePanel/ResourceLabel
@onready var _win_panel: Panel = $WinPanel
@onready var _lose_panel: Panel = $LosePanel


func _ready() -> void:
	GameState.resources_changed.connect(_on_resources_changed)
	GameState.organ_destroyed.connect(_on_win)
	GameState.all_units_dead.connect(_on_lose)
	_win_panel.visible = false
	_lose_panel.visible = false
	_on_resources_changed(GameState.resources)


func _on_resources_changed(amount: int) -> void:
	_resource_label.text = "Resource: %d" % amount


func _on_win() -> void:
	_win_panel.visible = true


func _on_lose() -> void:
	_lose_panel.visible = true
