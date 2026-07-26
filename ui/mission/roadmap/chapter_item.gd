extends VBoxContainer

@onready var title: Label = $Title
@onready var mission_container: HFlowContainer = $MissionContainer

@export var mission_item_scene: PackedScene

var id: String

func setup(chapter_data: ChapterData) -> void:
	id = chapter_data.id
	title.text = chapter_data.id.to_upper() + " | " + chapter_data.title
	for mission_data in chapter_data.missions:
		var mission_item = mission_item_scene.instantiate()
		mission_container.add_child(mission_item)
		mission_item.setup(chapter_data,mission_data)
