extends Node2D

signal device_selected(device: StaticBody2D)

# temp var for generating id's device
var computer_number_id: int = 0
var server_number_id: int = 0
var router_number_id: int = 0
var switch_number_id: int = 0
var selected_item = null
var is_placed: bool = false
var device: StaticBody2D = null
var device_data = null

func _ready() -> void:
	device_selected.connect(_on_device_selected)
	InventoryManager.item_selected.connect(_on_item_selected)

func _process(_delta: float) -> void:
	if selected_item and device and not is_placed:
		grab_to_mouse_position()

func _on_item_selected(item: ItemData) -> void:
	destroy_preview()
	selected_item = item
	if item is not PlaceableItem:
		return
	else:
		is_placed = false
		initialize_device()

func _on_device_selected(_device: StaticBody2D)->void:
	device = _device

func _unhandled_input(event: InputEvent) -> void:
	if selected_item == null:
		return
	if event.is_action_pressed("click_left") and selected_item is PlaceableItem:
		place_device()

func _generate_id(type: PlaceableItem.Type)-> String:
	var id: String
	if type == PlaceableItem.Type.COMPUTER:
		id = "computer_" + str(computer_number_id)
		computer_number_id += 1
	#if type == PlaceableItem.Type.SERVER:
		#id = "server_" + str(server_number_id)
		#server_number_id += 1
	#if type == PlaceableItem.Type.ROUTER:
		#id = "router_" + str(router_number_id)
		#router_number_id += 1
	#if type == PlaceableItem.Type.SWITCH:
		#id = "switch_" + str(switch_number_id)
		#switch_number_id += 1
	return id

func initialize_device() -> void:
	if not selected_item:
		return
	var container: Node2D
	var dev = selected_item.scene.instantiate()
	if selected_item.type == PlaceableItem.Type.COMPUTER:
		device_data = ComputerDevice.new(_generate_id(selected_item.type))
		container = get_tree().current_scene.find_child("Computers")
	dev.device_id = device_data.device_id
	device_selected.emit(dev)
	device.modulate.a = 0.5
	container.add_child(device)
	
func place_device() -> void:
	if not selected_item or not device:
		return
	is_placed = true
	device.modulate.a = 1
	NetworkManager.setup_device_data(device_data)
	device.load_device_data()
	InventoryManager.item_selected.emit(null)

func grab_to_mouse_position() -> void:
	device.global_position = get_global_mouse_position()

func destroy_preview() -> void:
	if device and not is_placed:
		device.queue_free()
		device_selected.emit(null)

func  remove_device(_device: StaticBody2D)-> void:
	if not selected_item and device and _device:
		return
	device_selected.emit(_device)
	device.queue_free()
	NetworkManager.remove_device_data(_device.device_id)
