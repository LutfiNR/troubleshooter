extends Control

@export var tabs: Array[TabBar]
@export var tab_container: TabContainer

var target_device_id: String = ""

func _ready() -> void:
	if tabs.size() > 0 and tabs[0] != null:
		if tabs[0].has_signal("packages_changed"):
			tabs[0].packages_changed.connect(_on_packages_changed)

func _on_packages_changed(_current_installed_packages: Array[String]) -> void:
	refresh_data()

func setup(device_id: String) -> void:
	target_device_id = device_id
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "":
		return
		
	# Gunakan Autoload terbaru
	var device = NetworkDeviceManager.get_device_data(target_device_id)
	if device == null or not (device is ServerDevice):
		return

	# Cek per Tab apakah software yang dibutuhkan sudah di-install
	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab == null:
			continue

		# Tab pertama (Software Manager) selalu bisa diakses
		if i == 0:
			tab_container.set_tab_disabled(i, false)
			continue
		
		# Ambil string 'package_need' dari script UI Tab yang bersangkutan
		var needed_package = tab.get("package_need")
		var is_installed = false
		
		if needed_package != null and needed_package != "":
			is_installed = device.is_package_installed(needed_package)
		else:
			# Jika tab tidak memiliki definisi package_need, izinkan diakses
			is_installed = true

		tab_container.set_tab_disabled(i, not is_installed)

	# Lempar data server ke masing-masing Tab UI
	for tab in tabs:
		if tab and tab.has_method("display_data"):
			tab.display_data(device, target_device_id)
