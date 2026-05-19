extends Node2D

# Preview scene shown before placing device
@onready var preview_scene: PackedScene = preload("uid://bfdg2lao8fnfl")

# Device id counters
var id_counters : Dictionary = {
	PlaceableItem.Type.COMPUTER: 0,
	PlaceableItem.Type.SERVER: 0,
	PlaceableItem.Type.ROUTER: 0,
	PlaceableItem.Type.SWITCH: 0
}
# Preview textures by device type
const PREVIEW_TEXTURE : Dictionary = {
	PlaceableItem.Type.COMPUTER: preload("uid://c3jkuuoqft25o"),
	PlaceableItem.Type.ROUTER: preload("uid://dg7uebr3q32ic"),
	PlaceableItem.Type.SWITCH: preload("uid://ce274dsb13ua5"),
	PlaceableItem.Type.SERVER: preload("uid://beqpwyanh864")
}
# Preview textures offset by device type
const PREVIEW_TEXTURE_OFFSET : Dictionary = {
	PlaceableItem.Type.COMPUTER: Vector2(0,-9),
	PlaceableItem.Type.ROUTER: Vector2(0,1),
	PlaceableItem.Type.SWITCH: Vector2(0,0),
	PlaceableItem.Type.SERVER: Vector2(0,0)
}
# Scene container names by device type
const CONTAINER_NAME : Dictionary = {
	PlaceableItem.Type.COMPUTER: "Computers",
	PlaceableItem.Type.SWITCH: "Switch",
	PlaceableItem.Type.ROUTER: "Router",
	PlaceableItem.Type.SERVER: "Server"
}
#device data type
var DEVICE_DATA_TYPE : Dictionary = {
	PlaceableItem.Type.COMPUTER: ComputerDevice,
	#PlaceableItem.Type.SWITCH: SwitchDevice,
	#PlaceableItem.Type.ROUTER: RouterDevice,
	#PlaceableItem.Type.SERVER: ServerDevice
}
#size tile grid
const TILE_GRID_SIZE: Vector2 = Vector2(16,16)
# Current selected inventory item
var selected_item: PlaceableItem = null
# Active preview sprite
var preview: Sprite2D = null
# Spawned device instance
var device: StaticBody2D = null
# Device resource data
var device_data: NetworkDevice = null
# Preview state
var is_preview : bool

func _ready() -> void:
	# Listen for inventory selection
	InventoryManager.item_selected.connect(_on_item_selected)

func _process(_delta: float) -> void:
	# Move preview to mouse position
	if selected_item and is_preview and preview:
		preview.global_position = get_global_mouse_position().snapped(TILE_GRID_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	# Place device on left click
	if event.is_action_pressed("click_left") and selected_item is PlaceableItem:
		place_device()

func _on_item_selected(item: ItemData) -> void:
	# Store selected placeable item
	selected_item = item as PlaceableItem
	if not selected_item:
		return
	else:
		init_preview()
		is_preview = true

func _generate_id(type: PlaceableItem.Type) -> String:
	# Generate unique device id
	var type_name : String = PlaceableItem.Type.keys()[type].to_lower()
	var id := "%s_%d" % [type_name, id_counters[type]]
	#increment id_counter
	id_counters[type] += 1
	return id

# Create placement preview
func init_preview() -> void:
	clear_preview()
	preview = preview_scene.instantiate()
	preview.texture = PREVIEW_TEXTURE.get(selected_item.type)
	preview.offset = PREVIEW_TEXTURE_OFFSET.get(selected_item.type)
	get_tree().current_scene.add_child(preview)

# Remove active preview
func clear_preview() -> void:
	if preview:
		preview.queue_free()
		preview = null
	device = null
	is_preview = false

# Spawn selected device
func place_device() -> void:
	if not selected_item or not preview:
		return

	#device_data conf
	device_data = DEVICE_DATA_TYPE.get(selected_item.type).new()
	device_data.device_id = _generate_id(selected_item.type)
	NetworkDeviceManager.setup_device_data(device_data)
	
	#device conf
	var container := get_tree().current_scene.find_child(CONTAINER_NAME[selected_item.type])
	device = selected_item.scene.instantiate()
	device.device_id = device_data.device_id
	device.global_position = preview.global_position
	container.add_child(device)
	device.load_device_data()
	#clearing
	clear_preview()
	InventoryManager.item_selected.emit(null)

# Remove device and data
func remove_device(target_device: StaticBody2D) -> void:
	if not target_device:
		return
	#update device data
	NetworkDeviceManager.remove_device_data(target_device.device_id)
	#free device
	target_device.queue_free()
