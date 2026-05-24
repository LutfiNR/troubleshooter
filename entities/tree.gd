extends Tree

const COLOR: Dictionary = {
	false: Color.CRIMSON,
	true: Color.GREEN,
}


func _ready() -> void:
	clear()
	populate_ui_tree()


func populate_ui_tree() -> void:
	var root = create_item()
	var data = MissionManager.get_mission_tree_data()
	for dev in data.keys():
		populate_device(root, data[dev])


func populate_device(parent: TreeItem, device: Dictionary) -> void:
	var tree = create_item(parent)
	tree.collapsed = true
	var text = device["hostname"]["correct"]
	tree.set_text(0, text)
	tree.set_custom_color(0, COLOR.get(device["status"]))

	populate_device_power_status(tree, device.get("power"))

	var iface_tree = create_item(tree)
	iface_tree.set_text(0, "Interfaces")
	iface_tree.set_custom_color(0, COLOR.get(device["interfaces"]["status"]))
	if device["interfaces"].has("results"):
		populate_interface(iface_tree, device.get("interfaces").get("results"))


func populate_interface(parent: TreeItem, interfaces: Dictionary) -> void:
	for iface in interfaces:
		var i_tree = create_item(parent)
		i_tree.set_text(0, iface)
		i_tree.set_custom_color(0, COLOR.get(interfaces[iface]["status"]))
		populate_interface_state_status(i_tree, interfaces[iface]["state"])
		populate_interface_ip(i_tree, interfaces[iface]["ip"])


func populate_device_power_status(parent: TreeItem, power: Dictionary) -> void:
	var dev_tree = create_item(parent)
	dev_tree.set_text(0, "State [ON]")
	dev_tree.set_custom_color(0, COLOR.get(power["status"]))


func populate_interface_state_status(parent: TreeItem, interface_state: Dictionary) -> void:
	var iface_status = create_item(parent)
	iface_status.set_text(0, "Power [ON]")
	iface_status.set_custom_color(0, COLOR.get(interface_state["status"]))


func populate_interface_ip(parent: TreeItem, interface_ip: Dictionary) -> void:
	if interface_ip.has("address"):
		var ip_address = create_item(parent)
		ip_address.set_text(0, "IP Address " + interface_ip["address"]["correct"])
		ip_address.set_custom_color(0, COLOR.get(interface_ip["address"]["status"]))
		var subnet_mask = create_item(parent)
		subnet_mask.set_text(0, "Subnet Mask " + interface_ip["subnet_mask"]["correct"])
		subnet_mask.set_custom_color(0, COLOR.get(interface_ip["subnet_mask"]["status"]))
