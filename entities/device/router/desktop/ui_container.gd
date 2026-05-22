extends Control

# Referensi ke Tab
@export var interface_tab: TabBar
@export var dhcp_relay_tab: TabBar

var target_device_id: String = ""

# =========================
# INITIALIZATION
# =========================
func setup(device_id: String) -> void:
	target_device_id = device_id
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "": return
	
	# Ubah ke NetworkDeviceManager
	var device = NetworkDeviceManager.get_device_data(target_device_id)
	if not device is RouterDevice: return
	
	# DISTRIBUSIKAN data ke masing-masing tab
	if interface_tab and interface_tab.has_method("display_data"):
		interface_tab.display_data(device, target_device_id)
	if dhcp_relay_tab and dhcp_relay_tab.has_method("display_data"):
		dhcp_relay_tab.display_data(device, target_device_id)
