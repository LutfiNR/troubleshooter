extends Panel

@export var chapter_item_scene: PackedScene
@onready var chapter_container: VBoxContainer = $ChapterContainer

func _ready() -> void:
	var chapter_datas: Array = GameManager.chapter_datas
	for chapter in chapter_datas:
		var chapter_item = chapter_item_scene.instantiate()
		chapter_container.add_child(chapter_item)
		chapter_item.setup(chapter)
