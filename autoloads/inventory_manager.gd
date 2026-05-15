extends Node2D

signal item_selected(item: ItemData)

var selected_item: ItemData = null

func _ready() -> void:
	item_selected.connect(_on_item_selected)

func _on_item_selected(item: ItemData = null) -> void:
	selected_item = item
