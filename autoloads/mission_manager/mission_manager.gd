extends Node

@export var correct_configuration: MissionData
@export var empty_configuration: MissionData


func _ready() -> void:
	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	if empty_configuration:
		load_mission_configuration(empty_configuration)


func load_mission_configuration(configuration: MissionData) -> void:
	if not configuration:
		return

	# Bersihkan papan simulasi sebelum memuat misi baru
	NetworkDeviceManager.computer_devices.clear()
	NetworkDeviceManager.server_devices.clear()
	NetworkDeviceManager.router_devices.clear()
	NetworkDeviceManager.switch_devices.clear()
	ConnectionManager.connections.clear()

	# Muat alat ke NetworkDeviceManager (gunakan duplicate agar data asli tidak tertimpa saat runtime)
	_load_devices_to_manager(configuration.computer_devices)
	_load_devices_to_manager(configuration.server_devices)
	_load_devices_to_manager(configuration.router_devices)
	_load_devices_to_manager(configuration.switch_devices)

	# Muat koneksi kabel ke ConnectionManager
	for conn_id in configuration.connections:
		ConnectionManager.setup_connection_data(configuration.connections[conn_id].duplicate(true))

	print("[MissionManager] Mission loaded: ", configuration.title)


func _load_devices_to_manager(devices_dict: Dictionary) -> void:
	for id in devices_dict:
		NetworkDeviceManager.add_device_data(devices_dict[id].duplicate(true))


func _on_device_updated(_device_id: String) -> void:
	# Evaluasi ulang seluruh misi setiap kali ada perubahan pada alat
	evaluate_mission()


func evaluate_mission() -> Dictionary:
	if not correct_configuration:
		push_warning("Correct configuration is missing for grading!")
		return { "mission_cleared": false }

	print_rich("\n[color=yellow]=== Starting Mission Verification ===[/color]")
	var is_mission_cleared = true
	var detailed_results = { }

	# Verifikasi semua kategori perangkat
	is_mission_cleared = _verify_category(NetworkDeviceManager.computer_devices, correct_configuration.computer_devices, detailed_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.server_devices, correct_configuration.server_devices, detailed_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.router_devices, correct_configuration.router_devices, detailed_results) and is_mission_cleared
	is_mission_cleared = _verify_category(NetworkDeviceManager.switch_devices, correct_configuration.switch_devices, detailed_results) and is_mission_cleared

	# Cek Koneksi Fisik (Apakah jumlah kabel sama dengan kunci jawaban)
	if ConnectionManager.connections.size() != correct_configuration.connections.size():
		is_mission_cleared = false
		print_rich("[color=red]Connection Mismatch:[/color] Expected ", correct_configuration.connections.size(), " connections, found ", ConnectionManager.connections.size())

	if is_mission_cleared:
		print_rich("[color=green]★ MISSION CLEARED! ALL CONFIGURATIONS PERFECT ★[/color]")
	else:
		print_rich("[color=orange]Mission Incomplete. Check logs for details.[/color]")

	return {
		"mission_cleared": is_mission_cleared,
		"details": detailed_results,
	}


func _verify_category(runtime_dict: Dictionary, correct_dict: Dictionary, results_out: Dictionary) -> bool:
	var category_cleared = true

	for correct_id in correct_dict:
		var correct_device = correct_dict[correct_id]

		# Kasus 1: Siswa menghapus / tidak membuat alat yang diwajibkan
		if not runtime_dict.has(correct_id):
			results_out[correct_id] = { "status": false, "error": "Device is missing" }
			category_cleared = false
			print_rich("[color=red]Missing:[/color] Device '", correct_id, "' is required but not found.")
			continue

		var runtime_device = runtime_dict[correct_id]
		var result = runtime_device.verify_configuration(correct_device)
		results_out[correct_id] = result

		# Kasus 2: Alat ada, tetapi konfigurasinya salah
		if not result.status:
			category_cleared = false
			print_rich("[color=red]Misconfigured:[/color] ", correct_id)
		else:
			print_rich("[color=green]Passed:[/color] ", correct_id)

	return category_cleared
