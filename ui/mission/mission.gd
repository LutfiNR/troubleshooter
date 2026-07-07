extends VBoxContainer

@export var task_item_scene: PackedScene

var task_item: Dictionary ={}

func _ready() -> void:
	NetworkManager.device_updated.connect(_on_device_updated)
	update_task()

func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	update_task()

func update_task() -> void:
	task_item.clear()
	var data: Dictionary = NetworkManager.mission_checking_result
	for key in data:
		if !data[key].status:
			task_item[key] = key
	print(task_item)
	
func create_task_item(title: String)->void:
	var task_item_node = task_item_scene.instantiate()
	add_child(task_item_node)
	task_item_node.set_title(title)
