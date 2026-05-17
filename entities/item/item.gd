extends TextureButton

@export var item_data: ItemData
@export var icon: TextureRect

func _ready() -> void:
	initialize()

func initialize() -> void:
	tooltip_text = item_data.name
	icon.texture = item_data.icon
	InventoryManager.item_selected.connect(_on_item_selected)

func _on_item_selected(item: ItemData) -> void:
	if item != item_data:
		set_pressed_no_signal(false)
		change_cursor_mouse(null)

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		InventoryManager.item_selected.emit(item_data)
		change_cursor_mouse(item_data.cursor_image)
	else:
		InventoryManager.item_selected.emit(null)
		change_cursor_mouse(null)

func change_cursor_mouse(image: Texture2D) -> void:
	Input.set_custom_mouse_cursor(image)
