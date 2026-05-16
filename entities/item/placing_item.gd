extends Node2D
class_name PlaceItemSystem

@export var computer_container: Node2D

var selected_item: PlaceableItem = null
var is_placed: bool = false
var device: StaticBody2D = null

func _ready() -> void:
	InventoryManager.item_selected.connect(_on_item_selected)

func _process(_delta: float) -> void:
	if selected_item and device and not is_placed:
		grab_to_mouse_position()

func _on_item_selected(item: ItemData) -> void:
	destroy_preview()
	if item is not PlaceableItem:
		selected_item = null
		return
	selected_item = item
	is_placed = false
	initialize_device()

func initialize_device() -> void:
	if not selected_item:
		return
	device = selected_item.scene.instantiate()
	device.modulate.a = 0.5
	computer_container.add_child(device)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click_left"):
		place_device()

func place_device() -> void:
	if not selected_item or not device:
		return
	is_placed = true
	device.modulate.a = 1
	assign_device_data()
	InventoryManager.item_selected.emit(null)

func assign_device_data()-> void:
	var device_data: NetworkDevice
	if selected_item.type == PlaceableItem.Type.COMPUTER:
		device_data = NetworkDevice.new()
		device_data.id = "computer_" + str(NetworkManager.get_devices_size())
	if selected_item.type == PlaceableItem.Type.SERVER:
		device_data = NetworkDevice.new()
		device_data.id = "server_" + str(NetworkManager.get_devices_size())
	if selected_item.type == PlaceableItem.Type.ROUTER:
		device_data = NetworkDevice.new()
		device_data.id = "router_" + str(NetworkManager.get_devices_size())
	if selected_item.type == PlaceableItem.Type.SWITCH:
		device_data = NetworkDevice.new()
		device_data.id = "switch_" + str(NetworkManager.get_devices_size())
	NetworkManager.setup_device(device_data)
	
func grab_to_mouse_position() -> void:
	device.global_position = get_global_mouse_position()

func destroy_preview() -> void:
	if device and not is_placed:
		device.queue_free()
		device = null
